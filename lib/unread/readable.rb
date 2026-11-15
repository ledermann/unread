module Unread
  module Readable
    module ClassMethods
      def mark_as_read!(target, options)
        raise ArgumentError unless options.is_a?(Hash)

        reader = options[:for]
        Internal.assert_reader!(reader)

        if target == :all
          # Called on a relation: mark only its records, not all records of the class
          if current_scope
            mark_collection_as_read(current_scope, reader)
          else
            reset_read_marks_for_user(reader)
          end
        elsif target.respond_to?(:each)
          mark_collection_as_read(target, reader)
        else
          raise ArgumentError
        end
      end

      # A scope with all items accessible for the given reader.
      # It's used in cleanup_read_marks! to support a filtered cleanup.
      # Override it if a reader doesn't have access to all items.
      # Default: reader has access to all items and should read them all
      #
      # Example:
      #   def Message.read_scope(reader)
      #     reader.visible_messages
      #   end
      def read_scope(_reader)
        self
      end

      def cleanup_read_marks!
        Internal.assert_reader_class!
        Unread::GarbageCollector.new(self).run!
      end

      private

      def mark_collection_as_read(collection, reader)
        ReadMark.transaction do
          global_timestamp = reader.read_mark_global(self)&.timestamp

          collection.each do |obj|
            raise ArgumentError unless obj.is_a?(self)

            timestamp = obj.public_send(readable_options[:on])

            # Skip objects which are implicitly marked as read by the global read mark
            next if global_timestamp && global_timestamp >= timestamp

            mark_collection_item_as_read(obj, reader, timestamp)
          end
        end
      end

      def mark_collection_item_as_read(obj, reader, timestamp)
        # The savepoint keeps the outer transaction usable after a unique
        # constraint violation (required by PostgreSQL)
        ReadMark.transaction(requires_new: true) do
          read_mark = obj.read_marks.find_or_initialize_by(reader:)
          read_mark.timestamp = timestamp
          read_mark.save!
        rescue ActiveRecord::RecordNotUnique
          # The object is already explicitly marked as read
          raise ActiveRecord::Rollback
        end
      end

      def reset_read_marks_for_user(reader)
        readable_type = Internal.readable_parent(self).name

        ReadMark.transaction do
          reader.read_marks.where(readable_type:).delete_all
          reader.read_marks.create!(readable_type:, timestamp: Time.current)
        end

        reader.send(:forget_memoized_read_mark_global)
      end
    end

    module InstanceMethods
      def unread?(reader)
        if respond_to?(:read_mark_id) && read_mark_id_belongs_to?(reader)
          # For use with scope "with_read_marks_for"
          return false if read_mark_id

          global_timestamp = reader.read_mark_global(self.class)&.timestamp
          global_timestamp.nil? || public_send(readable_options[:on]) > global_timestamp
        else
          self.class.unread_by(reader).exists?(id)
        end
      end

      def mark_as_read!(options)
        reader = options[:for]
        Internal.assert_reader!(reader)

        ReadMark.transaction do
          if unread?(reader)
            read_mark = read_marks.find_or_initialize_by(reader:)
            read_mark.timestamp = public_send(readable_options[:on])
            read_mark.save!
          end
        end
      end

      private

      def read_mark_id_belongs_to?(reader)
        read_mark_reader_id.to_i == reader.id &&
          read_mark_reader_type == reader.class.base_class.name
      end
    end
  end
end
