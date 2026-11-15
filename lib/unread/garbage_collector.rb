module Unread
  class GarbageCollector
    def initialize(readable_class)
      @readable_class = Internal.readable_parent(readable_class)
    end
    attr_reader :readable_class

    def run!
      ReadMark.reader_classes.each do |reader_class|
        readers_to_cleanup(reader_class).find_each do |reader|
          oldest_timestamp = readable_class
                             .read_scope(reader)
                             .unread_by(reader)
                             .minimum(readable_class.readable_options[:on])

          if oldest_timestamp
            # There are unread items, so update the global read_mark for this reader to the oldest
            # unread item and delete older read_marks
            update_read_marks_for_user(reader, oldest_timestamp)
          else
            # There is no unread item, so delete all markers and move global timestamp
            readable_class.mark_as_read!(:all, for: reader)
          end
        end
      end
    end

    private

    # Not every reader needs a cleanup.
    # Look for those readers with more than one read mark
    def readers_to_cleanup(reader_class)
      reader_ids = ReadMark
                   .where(readable_type: readable_class.name, reader_type: reader_class.base_class.name)
                   .group(:reader_id)
                   .having('COUNT(*) > 1')
                   .select(:reader_id)

      reader_class.reader_scope.where(reader_class.primary_key => reader_ids)
    end

    def update_read_marks_for_user(reader, timestamp)
      ReadMark.transaction do
        # Delete markers OLDER than the given timestamp
        reader.read_marks.where(readable_type: readable_class.name).single.older_than(timestamp).delete_all

        # Change the global timestamp for this reader
        read_mark = reader.read_mark_global(readable_class) || reader.read_marks.build(readable_type: readable_class.name)
        read_mark.update!(timestamp: timestamp - 1.second)
      end
    end
  end
end
