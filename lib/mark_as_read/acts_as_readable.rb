module MarkAsRead
  def self.included(base)
    base.extend ActsAsReadable
  end
  
  module ActsAsReadable
    def acts_as_readable(options={})
      options.reverse_merge!({ :on => :updated_at })
      class_inheritable_reader :readable_options
      write_inheritable_attribute :readable_options, options
      
      self.has_many :read_marks, :as => :readable, :dependent => :delete_all
      User.has_many :read_marks,                   :dependent => :delete_all

      User.after_create do |user|
        self.mark_as_read! :all, :for => user
      end
      
      named_scope :unread_by, lambda { |user| 
        user = Authorization.current_user if user == true 
        raise ArgumentError unless user.is_a?(User)

        result = { :joins => "LEFT JOIN read_marks ON read_marks.readable_type  = '#{self.base_class.name}'
                                                  AND read_marks.readable_id    = #{self.table_name}.id
                                                  AND read_marks.user_id        = #{user.id}
                                                  AND read_marks.timestamp     >= #{self.table_name}.#{readable_options[:on]}",
                   :conditions => 'read_marks.id IS NULL' }
        if last = last_timestamp(user)
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
      raise ArgumentError unless user.is_a?(User)
      
      if target == :all
        reset_read_marks!(user)
      elsif target.is_a?(Array)  
        ReadMark.transaction do
          last = last_timestamp(user)
      
          target.each do |id|
            raise ArgumentError unless id.is_a?(Integer)
        
            if rm = ReadMark.scoped_by_user_id(user.id).scoped_by_readable_type(self.base_class.name).find_by_readable_id(id)
              rm.update_attributes! :timestamp => Time.now
            else
              ReadMark.create! :user_id => user.id, :timestamp => Time.now, :readable_id => id, :readable_type => self.base_class.name
            end
          end
        end
      end
    end
    
    def global_read_mark(user)
      raise ArgumentError unless user.is_a?(User)
      user.read_marks.scoped_by_readable_type(self.base_class.name).global.first
    end
    
    def last_timestamp(user)
      global_read_mark(user).try(:timestamp)
    end

    def cleanup_read_marks!
      User.find_each do |user|
        mark_as_read!(:all, :for => user) unless unread_by(user).exists?
      end
    end
    
    def reset_read_marks!(user = :all)
      if user == :all
        ReadMark.delete_all :readable_type => self.base_class.name
        
        ReadMark.connection.execute("
          INSERT INTO read_marks (user_id, readable_type, timestamp)
          SELECT id, '#{self.base_class.name}', '#{Time.now.to_s(:db)}'
          FROM #{User.table_name}
        ")
      else
        ReadMark.delete_all :readable_type => self.base_class.name, :user_id => user.id
        ReadMark.create!    :readable_type => self.base_class.name, :user_id => user.id, :timestamp => Time.now
      end
      true
    end
  end
  
  module InstanceMethods 
    def unread?(user)
      self.class.unread_by(user).exists?(self)
    end
    
    def mark_as_read!(options)
      user = options[:for]
      raise ArgumentError unless user.is_a?(User)
      
      return true unless unread?(user)
      
      if rm = read_mark(user)
        rm.update_attributes! :timestamp => Time.now
      else
        read_marks.create! :user_id => user.id, :timestamp => Time.now
      end
    end

    def read_mark(user)
      read_marks.scoped_by_user_id(user.id).first
    end
  end
end

ActiveRecord::Base.send :include, MarkAsRead