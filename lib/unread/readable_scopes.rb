module Unread
  module Readable
    module Scopes
      def join_read_marks(user)
        assert_reader(user)

        joins "LEFT JOIN #{ReadMark.table_name} as read_marks
                ON read_marks.readable_type  = '#{base_class.name}'
               AND (read_marks.readable_id    = #{table_name}.#{primary_key}
                 OR read_marks.readable_id   IS NULL)
               AND read_marks.user_id        = #{user.id}
               AND read_marks.timestamp     >= #{table_name}.#{readable_options[:on]}"
      end

      def unread_by(user)
        result = join_read_marks(user).where('read_marks.id IS NULL')
        user.set_read_mark_global(self)
        result
      end

      def read_by(user)
        result = join_read_marks(user).where('read_marks.id IS NOT NULL')
        user.set_read_mark_global(self)
        result
      end

      def with_read_marks_for(user)
        join_read_marks(user).select("#{table_name}.*, read_marks.id AS read_mark_id")
      end
    end
  end
end
