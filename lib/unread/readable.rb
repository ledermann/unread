module Unread
  module Readable
    module ClassMethods
      def mark_as_read!(target, options)
        raise ArgumentError unless options.is_a?(Hash)

        reader = options[:for]
        assert_reader(reader)

        if target == :all
          reset_read_marks_for_user(reader)
        elsif target.respond_to?(:each)
          mark_collection_as_read(target, reader)
        else
          raise ArgumentError
        end
      end

      def mark_collection_as_read(collection, reader)
        ReadMark.transaction do
          global_timestamp = reader.read_mark_global(self).try(:timestamp)

          collection.each do |obj|
            raise ArgumentError unless obj.is_a?(self)
            timestamp = obj.send(readable_options[:on])

            if global_timestamp && global_timestamp >= timestamp
              # The object is implicitly marked as read, so there is nothing to do
            else
              mark_collection_item_as_read(obj, reader, timestamp)
            end
          end
        end
      end

      def mark_collection_item_as_read(obj, reader, timestamp)
        marking_proc = proc {
          rm = obj.read_marks.find_or_initialize_by(reader: reader)
          rm.timestamp = timestamp
          rm.save!
        }

        if using_postgresql?
          # With PostgreSQL, a transaction is unusable after a unique constraint vialoation.
          # To avoid this, nested transactions are required.
          # http://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Exception+handling+and+rolling+back
          ReadMark.transaction(requires_new: true) do
            begin
              marking_proc.call
            rescue ActiveRecord::RecordNotUnique
              # The object is explicitly marked as read, so rollback the inner transaction
              raise ActiveRecord::Rollback
            end
          end
        else
          begin
            marking_proc.call
          rescue ActiveRecord::RecordNotUnique
            # The object is explicitly marked as read, so there is nothing to do
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

      def readable_parent
        self.ancestors.find { |ancestor| ReadMark.readable_classes.include?(ancestor) }
      end

      def cleanup_read_marks!
        assert_reader_class
        Unread::GarbageCollector.new(self).run!
      end

      def reset_read_marks_for_user(reader)
        assert_reader(reader)

        ReadMark.transaction do
          reader.read_marks.where(readable_type: self.readable_parent.name).delete_all
          rm = reader.read_marks.new
          rm.readable_type = self.readable_parent.name
          rm.timestamp = Time.current
          rm.save!
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

      private

      def read_mark(reader)
        read_marks.where(reader_id: reader.id, reader_type: reader.class.base_class.name).first
      end

      def read_mark_id_belongs_to?(reader)
        self.read_mark_reader_id.to_i == reader.id &&
          self.read_mark_reader_type == reader.class.base_class.name
      end
    end
  end
end
