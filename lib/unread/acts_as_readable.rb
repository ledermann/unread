module Unread
  def self.included(base)
    base.extend ActsAsReadable
  end
  
  module ActsAsReadable
    def acts_as_reader
      ReadMark.write_inheritable_attribute :reader_class, self
      
      has_many :read_marks, :dependent => :delete_all
      
      after_create do |user|
        (ReadMark.readable_classes || []).each do |klass|
          klass.mark_as_read! :all, :for => user
        end
      end
    end
    
    def acts_as_readable(options={})
      options.reverse_merge!({ :on => :updated_at })
      class_inheritable_reader :readable_options
      write_inheritable_attribute :readable_options, options
      
      self.has_many :read_marks, :as => :readable, :dependent => :delete_all
      
      classes = ReadMark.readable_classes || []
      classes << self
      ReadMark.write_inheritable_attribute :readable_classes, classes
      
      scope_method = ActiveRecord::VERSION::MAJOR == 2 ? :named_scope : :scope
      
      send scope_method, :unread_by, lambda { |user| 
        check_reader
        raise ArgumentError unless user.is_a?(ReadMark.reader_class)

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
      check_reader
      raise ArgumentError unless target == :all || target.is_a?(Array)
      
      user = options[:for]
      raise ArgumentError unless user.is_a?(ReadMark.reader_class)
      
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
      check_reader
      raise ArgumentError unless user.is_a?(ReadMark.reader_class)
      
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
      check_reader
      
      ReadMark.reader_class.find_each do |user|
        ReadMark.transaction do
          # Get the timestamp of the oldest unread item the user has access to
          oldest_timestamp = read_scope(user).unread_by(user).minimum(readable_options[:on])

          if oldest_timestamp
            # Delete markers OLDER than this timestamp and move the global timestamp for this user
            user.read_marks.single.older_than(oldest_timestamp).delete_all
            set_read_mark(user, oldest_timestamp - 1.second)
          else
            # There is no unread item, so mark all as read (which deletes all markers)
            mark_as_read!(:all, :for => user)
          end
        end
      end
    end
    
    def reset_read_marks!(user = :all)
      check_reader

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
    
    def check_reader
      raise RuntimeError, 'Plugin "unread": No reader defined!' unless ReadMark.reader_class
    end
  end
  
  module InstanceMethods 
    def unread?(user)
      self.class.unread_by(user).exists?(self)
    end
    
    def mark_as_read!(options)
      self.class.check_reader
      
      user = options[:for]
      raise ArgumentError unless user.is_a?(ReadMark.reader_class)
      
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