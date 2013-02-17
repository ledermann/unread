module Unread
  def self.included(base)
    base.extend ActsAsReadable
  end

  module ActsAsReadable
    def acts_as_reader
      ReadMark.belongs_to :user, :class_name => self.to_s

      has_many :read_marks, :dependent => :delete_all, :foreign_key => 'user_id', :inverse_of => :user

      after_create do |user|
        # We assume that a new user should not be tackled by tons of old messages
        # created BEFORE he signed up.
        # Instead, the new user starts with zero unread messages
        (ReadMark.readable_classes || []).each do |klass|
          klass.mark_as_read! :all, :for => user
        end
      end

      include ReaderInstanceMethods
    end

    def acts_as_readable(options={})
      class_attribute :readable_options

      options.reverse_merge!(:on => :updated_at)
      self.readable_options = options

      has_many :read_marks, :as => :readable, :dependent => :delete_all

      ReadMark.readable_classes ||= []
      ReadMark.readable_classes << self unless ReadMark.readable_classes.include?(self)

      scope :join_read_marks, lambda { |user|
        assert_reader(user)

        joins "LEFT JOIN read_marks ON read_marks.readable_type  = '#{self.base_class.name}'
                                   AND read_marks.readable_id    = #{self.table_name}.id
                                   AND read_marks.user_id        = #{user.id}
                                   AND read_marks.timestamp     >= #{self.table_name}.#{readable_options[:on]}"
      }

      scope :unread_by, lambda { |user|
        result = join_read_marks(user).
                 where('read_marks.id IS NULL')

        if global_time_stamp = user.read_mark_global(self).try(:timestamp)
          result = result.where("#{self.table_name}.#{readable_options[:on]} > '#{global_time_stamp.to_s(:db)}'")
        end

        result
      }

      scope :with_read_marks_for, lambda { |user|
        join_read_marks(user).select("#{self.table_name}.*, read_marks.id AS read_mark_id")
      }

      extend ReadableClassMethods
      include ReadableInstanceMethods
    end
  end

  module ReadableClassMethods
    def mark_as_read!(target, options)
      user = options[:for]
      assert_reader(user)

      if target == :all
        reset_read_marks!(user)
      elsif target.is_a?(Array)
        mark_array_as_read(target, user)
      else
        raise ArgumentError
      end
    end

    def mark_array_as_read(array, user)
      ReadMark.transaction do
        array.each do |obj|
          raise ArgumentError unless obj.is_a?(self)

          rm = ReadMark.where(:user_id => user.id, :readable_type => self.base_class.name).find_by_readable_id(obj.id) ||
               user.read_marks.build(:readable_id => obj.id, :readable_type => self.base_class.name)
          rm.timestamp = obj.send(readable_options[:on])
          rm.save!
        end
      end
    end

    def set_read_mark(user, timestamp)
      rm = user.read_mark_global(self) || user.read_marks.build(:readable_type => self.base_class.name)
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
      assert_reader_class

      ReadMark.reader_class.find_each do |user|
        ReadMark.transaction do
          # Get the timestamp of the oldest unread item the user has access to
          oldest_timestamp = read_scope(user).unread_by(user).minimum(readable_options[:on])

          if oldest_timestamp
            # Delete markers OLDER than this timestamp and move the global timestamp for this user
            user.read_marks.single.where(:readable_type => self.base_class.name).older_than(oldest_timestamp).delete_all
            set_read_mark(user, oldest_timestamp - 1.second)
          else
            # There is no unread item, so mark all as read (which deletes all markers)
            mark_as_read!(:all, :for => user)
          end
        end
      end
    end

    def reset_read_marks!(user=nil)
      assert_reader_class

      if user
        reset_read_marks_for_user(user)
      else
        reset_read_marks_for_all_users
      end
    end

    def reset_read_marks_for_all_users
      ReadMark.transaction do
        ReadMark.delete_all :readable_type => self.base_class.name
        ReadMark.connection.execute <<-EOT
          INSERT INTO read_marks (user_id, readable_type, timestamp)
          SELECT id, '#{self.base_class.name}', '#{Time.now.to_s(:db)}'
          FROM #{ReadMark.reader_class.table_name}
        EOT
      end
    end

    def reset_read_marks_for_user(user)
      assert_reader(user)

      ReadMark.transaction do
        ReadMark.delete_all :readable_type => self.base_class.name, :user_id => user.id
        ReadMark.create!    :readable_type => self.base_class.name, :user_id => user.id, :timestamp => Time.now
      end
    end

    def assert_reader(user)
      assert_reader_class

      raise ArgumentError, "Class #{user.class.name} is not registered by acts_as_reader!" unless user.is_a?(ReadMark.reader_class)
      raise ArgumentError, "The given user has no id!" unless user.id
    end

    def assert_reader_class
      raise RuntimeError, 'There is no class using acts_as_reader!' unless ReadMark.reader_class
    end
  end

  module ReadableInstanceMethods
    def unread?(user)
      if self.respond_to?(:read_mark_id)
        # For use with scope "with_read_marks_for"
        return false if self.read_mark_id

        if global_timestamp = user.read_mark_global(self.class).try(:timestamp)
          self.send(readable_options[:on]) > global_timestamp
        else
          true
        end
      else
        self.class.unread_by(user).exists?(self)
      end
    end

    def mark_as_read!(options)
      user = options[:for]
      self.class.assert_reader(user)

      ReadMark.transaction do
        if unread?(user)
          rm = read_mark(user) || read_marks.build(:user_id => user.id)
          rm.timestamp = self.send(readable_options[:on])
          rm.save!
        end
      end
    end

    def read_mark(user)
      read_marks.where(:user_id => user.id).first
    end
  end

  module ReaderInstanceMethods
    def read_mark_global(klass)
      instance_var_name = "@read_mark_global_#{klass.name.gsub('::','_')}"
      instance_variable_get(instance_var_name) || begin # memoize
        obj = self.read_marks.where(:readable_type => klass.base_class.name).global.first
        instance_variable_set(instance_var_name, obj)
      end
    end
  end
end

ActiveRecord::Base.send :include, Unread
