module Unread
  module Reader
    module Scopes
      # This class method may be overriden to restrict readers to a subset of records
      # It must return self or a ActiveRecord::Relation
      def reader_scope
        self
      end

      def join_read_marks(readable)
        assert_readable(readable)

        joins "LEFT JOIN read_marks
                ON read_marks.readable_type  = '#{readable.readable_parent.name}'
               AND (read_marks.readable_id   = #{readable.id} OR read_marks.readable_id IS NULL)
               AND read_marks.reader_id      = #{quoted_table_name}.#{quoted_primary_key}
               AND read_marks.reader_type    = '#{connection.quote_string base_class.name}'
               AND read_marks.timestamp     >= '#{connection.quoted_date readable.send(readable.class.readable_options[:on])}'"
      end

      def have_not_read(readable)
        join_read_marks(readable).where('read_marks.id IS NULL')
      end

      def have_read(readable)
        join_read_marks(readable).where('read_marks.id IS NOT NULL')
      end

      def with_read_marks_for(readable)
        join_read_marks(readable).select("#{quoted_table_name}.*, read_marks.id AS read_mark_id,
                                         '#{readable.class.name}' AS read_mark_readable_type,
                                          #{readable.id} AS read_mark_readable_id")
      end
    end
  end
end
