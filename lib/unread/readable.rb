module Unread
  module Readable
    module ClassMethods
      def mark_as_read!(target, options)
        raise ArgumentError unless options.is_a?(Hash)

        reader = options[:for]
        assert_reader(reader)

        if target == :all
          reset_read_marks_for_user(reader)
        elsif target.is_a?(Array)
          mark_array_as_read(target, reader)
        else
          raise ArgumentError
        end
      end

      def mark_array_as_read(array, reader)
        ReadMark.transaction do
          global_timestamp = reader.read_mark_global(self).try(:timestamp)

          array.each do |obj|
            raise ArgumentError unless obj.is_a?(self)
            timestamp = obj.send(readable_options[:on])

            if global_timestamp && global_timestamp >= timestamp
              # The object is implicitly marked as read, so there is nothing to do
            else
              rm = obj.read_marks.where(:reader_id => reader.id, :reader_type => reader.class.base_class.name).first || obj.read_marks.build
              rm.reader_id   = reader.id
              rm.reader_type = reader.class.base_class.name
              rm.timestamp   = timestamp
              rm.save!
            end
          end
        end
      end

      # A scope with all items accessable for the given reader
      # It's used in cleanup_read_marks! to support a filtered cleanup
      # Should be overriden if a reader doesn't have access to all items
      # Default: reader has access to all items and should read them all
      #
      # Example:
      #   def Message.read_scope(reader)
      #     reader.visible_messages
      #   end
      def read_scope(reader)
        self
      end

      def cleanup_read_marks!
        assert_reader_class

        ReadMark.reader_classes.each do |reader_class|
          ReadMark.reader_scope(reader_class).find_each do |reader|
            if oldest_timestamp = read_scope(reader).unread_by(reader).minimum(readable_options[:on])
              # There are unread items, so update the global read_mark for this reader to the oldest
              # unread item and delete older read_marks
              update_read_marks_for_user(reader, oldest_timestamp)
            else
              # There is no unread item, so deletes all markers and move global timestamp
              reset_read_marks_for_user(reader)
            end
          end
        end
      end

      def update_read_marks_for_user(reader, timestamp)
        ReadMark.transaction do
          # Delete markers OLDER than the given timestamp
          reader.read_marks.where(:readable_type => self.base_class.name).single.older_than(timestamp).delete_all

          # Change the global timestamp for this reader
          rm = reader.read_mark_global(self) || reader.read_marks.build
          rm.readable_type = self.base_class.name
          rm.timestamp     = timestamp - 1.second
          rm.save!
        end
      end

      def reset_read_marks_for_all
        ReadMark.transaction do
          ReadMark.delete_all :readable_type => self.base_class.name

          ReadMark.reader_classes.each do |reader_class|
            # Build a SELECT statement with all relevant readers
            reader_sql = ReadMark.
                           reader_scope(reader_class).
                           select("#{reader_class.quoted_table_name}.#{reader_class.quoted_primary_key},
                                  '#{reader_class.base_class}',
                                  '#{self.base_class.name}',
                                  '#{connection.quoted_date Time.current}'").to_sql

            ReadMark.connection.execute <<-EOT
              INSERT INTO read_marks (reader_id, reader_type, readable_type, timestamp)
              #{reader_sql}
            EOT
          end
        end
      end

      def reset_read_marks_for_user(reader)
        assert_reader(reader)

        ReadMark.transaction do
          ReadMark.delete_all :readable_type => self.base_class.name, :reader_id => reader.id, :reader_type => reader.class.base_class.name

          ReadMark.create! do |rm|
            rm.readable_type = self.base_class.name
            rm.reader_id     = reader.id
            rm.reader_type   = reader.class.base_class.name
            rm.timestamp     = Time.current
          end
        end

        reader.forget_memoized_read_mark_global
      end

      def assert_reader(reader)
        assert_reader_class

        raise ArgumentError, "Class #{reader.class.name} is not registered by acts_as_reader." unless ReadMark.reader_classes.any? { |klass| reader.is_a?(klass) }
        raise ArgumentError, "The given reader has no id." unless reader.id
      end

      def assert_reader_class
        raise RuntimeError, 'There is no class using acts_as_reader.' unless ReadMark.reader_classes
      end
    end

    module InstanceMethods
      def unread?(reader)
        if self.respond_to?(:read_mark_id) && read_mark_id_belongs_to?(reader)
          # For use with scope "with_read_marks_for"
          return false if self.read_mark_id

          if global_timestamp = reader.read_mark_global(self.class).try(:timestamp)
            self.send(readable_options[:on]) > global_timestamp
          else
            true
          end
        else
          self.class.unread_by(reader).exists?(self.id)
        end
      end

      def mark_as_read!(options)
        reader = options[:for]
        self.class.assert_reader(reader)

        ReadMark.transaction do
          if unread?(reader)
            rm = read_mark(reader) || read_marks.build
            rm.reader_id   = reader.id
            rm.reader_type = reader.class.base_class.name
            rm.timestamp   = self.send(readable_options[:on])
            rm.save!
          end
        end
      end

      def read_mark(reader)
        read_marks.where(:reader_id => reader.id, reader_type: reader.class.base_class.name).first
      end

      private

      def read_mark_id_belongs_to?(reader)
        self.read_mark_reader_id == reader.id &&
          self.read_mark_reader_type == reader.class.base_class.name
      end
    end
  end
end
