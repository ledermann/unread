module Unread
  module Readable
    module Scopes
      def join_read_marks(user)
        assert_reader(user)

        joins "LEFT JOIN read_marks
                ON read_marks.readable_type  = '#{base_class.name}'
               AND read_marks.readable_id    = #{quoted_table_name}.#{quoted_primary_key}
               AND read_marks.user_id        = #{user.id}
               AND read_marks.timestamp     >= #{quoted_table_name}.#{connection.quote_column_name(readable_options[:on])}"
      end

      def unread_by(user)
        result = join_read_marks(user)

        if global_time_stamp = user.read_mark_global(self).try(:timestamp)
          result = result.where("read_marks.id IS NULL
                                 AND #{quoted_table_name}.#{connection.quote_column_name(readable_options[:on])} > ?", global_time_stamp)
        else
          result = result.where('read_marks.id IS NULL')
        end

        result
      end

      def read_by(user)
        result = join_read_marks(user)

        if global_time_stamp = user.read_mark_global(self).try(:timestamp)
          result = result.where("read_marks.id IS NOT NULL
                                 OR #{quoted_table_name}.#{connection.quote_column_name(readable_options[:on])} <= ?", global_time_stamp)
        else
          result = result.where('read_marks.id IS NOT NULL')
        end

        result
      end

      def with_read_marks_for(user)
        join_read_marks(user).select("#{quoted_table_name}.*,
                                     read_marks.id AS read_mark_id,
                                     #{user.id} AS read_mark_user_id")
      end
    end
  end
end
