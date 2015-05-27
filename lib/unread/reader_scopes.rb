module Unread
  module Reader
    module Scopes
      def join_read_marks(readable)
        assert_readable(readable)

        joins "LEFT JOIN read_marks
                ON read_marks.readable_type  = '#{readable.class.base_class.name}'
               AND (read_marks.readable_id   = #{readable.id} OR read_marks.readable_id IS NULL)
               AND read_marks.user_id        = #{quoted_table_name}.#{quoted_primary_key}
               AND read_marks.timestamp     >= '#{connection.quoted_date readable.send(readable.class.readable_options[:on])}'"
      end

      def have_not_read(readable)
        join_read_marks(readable).where("read_marks.id IS NULL")
      end

      def have_read(readable)
        join_read_marks(readable).where('read_marks.id IS NOT NULL')
      end

      def with_read_marks_for(readable)
        join_read_marks(readable).select("#{quoted_table_name}.*, read_marks.id AS read_mark_id,
                                         '#{readable.class.base_class.name}' AS read_mark_readable_type,
                                          #{readable.id} AS read_mark_readable_id")
      end
    end
  end
end