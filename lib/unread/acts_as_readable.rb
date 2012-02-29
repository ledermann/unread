module Unread
  def self.included(base)
    base.extend ActsAsReadable
  end
  
  module ActsAsReadable
    def acts_as_reader
      ReadMark.belongs_to :user, :class_name => self.to_s
      
      has_many :read_marks, :dependent => :delete_all, :foreign_key => 'user_id', :inverse_of => :user
      
      after_create do |user|
        (ReadMark.readable_classes || []).each do |klass|
          klass.mark_as_read! :all, :for => user
        end
      end
    end
    
    def acts_as_readable(options={})
      if respond_to?(:class_attribute)
        class_attribute :readable_options
      else
        class_inheritable_accessor :readable_options
      end

      options.reverse_merge!({ :on => :updated_at })
      self.readable_options = options
      
      has_many :read_marks, :as => :readable, :dependent => :delete_all
      
      ReadMark.readable_classes ||= []
      ReadMark.readable_classes << self unless ReadMark.readable_classes.map(&:name).include?(self.name)
      
      scope_method = ActiveRecord::VERSION::MAJOR < 3 ? :named_scope : :scope
      
      send scope_method, :unread_by, lambda { |user| 
        assert_reader(user)

        result = { :joins => "LEFT JOIN read_marks ON read_marks.readable_type  = '#{self.base_class.name}'
                                                  AND read_marks.readable_id    = #{self.table_name}.id
                                                  AND read_marks.user_id        = #{user.id}
                                                  AND read_marks.timestamp     >= #{self.table_name}.#{readable_options[:on]}",
                   :conditions => 'read_marks.id IS NULL' }
        if last = read_timestamp(user)
          result[:conditions] += " AND #{self.table_name}.#{readable_options[:on]} > '#{last.to_s(:db)}'"
        end
        result
      }
      
      extend ClassMethods
      include InstanceMethods
    end
  end
  
  module ClassMethods
    def mark_as_read!(target, options)
      raise ArgumentError unless target == :all || target.is_a?(Array)
      
      user = options[:for]
      assert_reader(user)
      
      if target == :all
        reset_read_marks!(user)
      elsif target.is_a?(Array)  
        ReadMark.transaction do
          last = read_timestamp(user)
      
          target.each do |obj|
            raise ArgumentError unless obj.is_a?(self)
        
            rm = ReadMark.user(user).readable_type(self.base_class.name).find_by_readable_id(obj.id) ||
                 user.read_marks.build(:readable_id => obj.id, :readable_type => self.base_class.name)
            rm.timestamp = obj.send(readable_options[:on])
            rm.save!
          end
        end
      end
    end
    
    def read_mark(user)
      assert_reader(user)
      user.read_marks.readable_type(self.base_class.name).global.first
    end
    
    def read_timestamp(user)
      read_mark(user).try(:timestamp)
    end

    def set_read_mark(user, timestamp)
      rm = read_mark(user) || user.read_marks.build(:readable_type => self.base_class.name)
      rm.timestamp = timestamp
      rm.save!
    end    

    # A scope with all items accessable for the given user
    # It's used in cleanup_read_marks! to support a filtered cleanup
    # Should be overriden if a user doesn't have access to all items
    # Default: User has access to all items and should read them all
    #
    # Example:
    #   def Message.read_scope(user)
    #     user.visible_messages
    #   end
    def read_scope(user)
      self
    end

    def cleanup_read_marks!
      assert_reader
      
      ReadMark.reader_class.find_each do |user|
        ReadMark.transaction do
          # Get the timestamp of the oldest unread item the user has access to
          oldest_timestamp = read_scope(user).unread_by(user).minimum(readable_options[:on])

          if oldest_timestamp
            # Delete markers OLDER than this timestamp and move the global timestamp for this user
            user.read_marks.readable_type(self.base_class.name).single.older_than(oldest_timestamp).delete_all
            set_read_mark(user, oldest_timestamp - 1.second)
          else
            # There is no unread item, so mark all as read (which deletes all markers)
            mark_as_read!(:all, :for => user)
          end
        end
      end
    end
    
    def reset_read_marks!(user = :all)
      assert_reader

      ReadMark.transaction do
        if user == :all
          ReadMark.delete_all :readable_type => self.base_class.name
      
          ReadMark.connection.execute("
            INSERT INTO read_marks (user_id, readable_type, timestamp)
            SELECT id, '#{self.base_class.name}', '#{Time.now.to_s(:db)}'
            FROM #{ReadMark.reader_class.table_name}
          ")
        else
          ReadMark.delete_all :readable_type => self.base_class.name, :user_id => user.id
          ReadMark.create!    :readable_type => self.base_class.name, :user_id => user.id, :timestamp => Time.now
        end
      end
      true
    end
    
    def assert_reader(user=nil)
      if ReadMark.reader_class
        if user && !user.is_a?(ReadMark.reader_class)
          raise ArgumentError, "Class #{user.class.name} is not registered by acts_as_reader!"
        end
      else
        raise RuntimeError, 'There is no class using acts_as_reader!'
      end
    end
  end
  
  module InstanceMethods 
    def unread?(user)
      self.class.unread_by(user).exists?(self)
    end
    
    def mark_as_read!(options)
      user = options[:for]
      self.class.assert_reader(user)
      
      ReadMark.transaction do
        if unread?(user)
          rm = read_mark(user) || read_marks.build(:user => user)
          rm.timestamp = self.send(readable_options[:on])
          rm.save!
        end
      end
    end

    def read_mark(user)
      read_marks.user(user).first
    end
  end
end

ActiveRecord::Base.send :include, Unread
