module Unread
  module Readable
    module ClassMethods
      def mark_as_read!(target, options)
        raise ArgumentError unless options.is_a?(Hash)

        user = options[:for]
        assert_reader(user)

        if target == :all
          reset_read_marks_for_user(user)
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

            rm = obj.read_marks.where(:user_id => user.id).first || obj.read_marks.build(:user_id => user.id)
            rm.timestamp = obj.send(readable_options[:on])
            rm.save!
          end
        end
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
            if oldest_timestamp = read_scope(user).unread_by(user).minimum(readable_options[:on])
              # There are unread items, so update the global read_mark for this user to the oldest
              # unread item and delete older read_marks
              update_read_marks_for_user(user, oldest_timestamp)
            else
              # There is no unread item, so deletes all markers and move global timestamp
              reset_read_marks_for_user(user)
            end
          end
        end
      end

      def update_read_marks_for_user(user, timestamp)
        # Delete markers OLDER than the given timestamp
        user.read_marks.where(:readable_type => self.base_class.name).single.older_than(timestamp).delete_all

        # Change the global timestamp for this user
        rm = user.read_mark_global(self) || user.read_marks.build(:readable_type => self.base_class.name)
        rm.timestamp = timestamp - 1.second
        rm.save!
      end

      def reset_read_marks_for_all
        ReadMark.transaction do
          ReadMark.delete_all :readable_type => self.base_class.name
          ReadMark.connection.execute <<-EOT
            INSERT INTO #{ReadMark.table_name} (user_id, readable_type, timestamp)
            SELECT #{ReadMark.reader_class.primary_key}, '#{self.base_class.name}', '#{Time.current.to_s(:db)}'
            FROM #{ReadMark.reader_class.table_name}
          EOT
        end
      end

      def reset_read_marks_for_user(user)
        assert_reader(user)

        ReadMark.transaction do
          ReadMark.delete_all :readable_type => self.base_class.name, :user_id => user.id
          ReadMark.create!    :readable_type => self.base_class.name, :user_id => user.id, :timestamp => Time.current
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

    module InstanceMethods
      def unread?(user)
        if self.respond_to?(:read_mark_id) and read_mark_id_belongs_to?(user)
          # For use with scope "with_read_marks_for"
          return false if self.read_mark_id

          if global_timestamp = user.read_mark_global(self.class).try(:timestamp)
            self.send(readable_options[:on]) > global_timestamp
          else
            true
          end
        else
          !!self.class.unread_by(user).exists?(self) # Rails4 does not return true/false, but nil/count instead.
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

      private
        def read_mark_id_belongs_to?(user)
          self.read_mark_user_id == user.id
        end
    end
  end
end
