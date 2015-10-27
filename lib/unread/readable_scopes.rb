module Unread
  module Readable
    module Scopes
      def join_read_marks(reader)
        assert_reader(reader)

        joins "LEFT JOIN read_marks
                ON read_marks.readable_type  = '#{base_class.name}'
               AND read_marks.readable_id    = #{quoted_table_name}.#{quoted_primary_key}
               AND read_marks.reader_id      = #{quote_bound_value(reader.id)}
               AND read_marks.reader_type    = #{quote_bound_value(reader.class.base_class.name)}
               AND read_marks.timestamp     >= #{quoted_table_name}.#{connection.quote_column_name(readable_options[:on])}"
      end

      def unread_by(reader)
        result = join_read_marks(reader)

        if global_time_stamp = reader.read_mark_global(self).try(:timestamp)
          result.where("read_marks.id IS NULL
                        AND #{quoted_table_name}.#{connection.quote_column_name(readable_options[:on])} > ?", global_time_stamp)
        else
          result.where('read_marks.id IS NULL')
        end
      end

      def read_by(reader)
        result = join_read_marks(reader)

        if global_time_stamp = reader.read_mark_global(self).try(:timestamp)
          result.where("read_marks.id IS NOT NULL
                        OR #{quoted_table_name}.#{connection.quote_column_name(readable_options[:on])} <= ?", global_time_stamp)
        else
          result.where('read_marks.id IS NOT NULL')
        end
      end

      def with_read_marks_for(reader)
        join_read_marks(reader).select("#{quoted_table_name}.*,
                                     read_marks.id AS read_mark_id,
                                     #{quote_bound_value(reader.class.base_class.name)} AS read_mark_reader_type,
                                     #{quote_bound_value(reader.id)} AS read_mark_reader_id")
      end
    end
  end
end
