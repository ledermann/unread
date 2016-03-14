module Unread
  class GarbageCollector
    def initialize(readable_class)
      @readable_class = readable_class.readable_parent
    end
    attr_reader :readable_class

    def run!
      ReadMark.reader_classes.each do |reader_class|
        readers_to_cleanup(reader_class).each do |reader|
          if oldest_timestamp = readable_class.read_scope(reader).
                                  unread_by(reader).
                                  minimum(readable_class.readable_options[:on])
            # There are unread items, so update the global read_mark for this reader to the oldest
            # unread item and delete older read_marks
            update_read_marks_for_user(reader, oldest_timestamp)
          else
            # There is no unread item, so deletes all markers and move global timestamp
            readable_class.reset_read_marks_for_user(reader)
          end
        end
      end
    end

  private
    # Not for every reader a cleanup is needed.
    # Look for those readers with at least one single read mark
    def readers_to_cleanup(reader_class)
      reader_class.
        reader_scope.
        joins(:read_marks).
        where(ReadMark.table_name => { :readable_type => readable_class.name }).
        group("#{ReadMark.quoted_table_name}.reader_type, #{ReadMark.quoted_table_name}.reader_id, #{reader_class.quoted_table_name}.#{reader_class.quoted_primary_key}").
        having("COUNT(#{ReadMark.quoted_table_name}.id) > 1")
    end

    def update_read_marks_for_user(reader, timestamp)
      ReadMark.transaction do
        # Delete markers OLDER than the given timestamp
        reader.read_marks.
          where(:readable_type => readable_class.name).
          single.
          older_than(timestamp).
          delete_all

        # Change the global timestamp for this reader
        rm = reader.read_mark_global(readable_class) || reader.read_marks.build
        rm.readable_type = readable_class.name
        rm.timestamp     = timestamp - 1.second
        rm.save!
      end
    end
  end
end
