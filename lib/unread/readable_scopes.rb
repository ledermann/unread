module Unread
  module Readable
    module Scopes
      def join_read_marks(reader)
        assert_reader(reader)

        joins "LEFT JOIN #{ReadMark.quoted_table_name}
                ON #{ReadMark.quoted_table_name}.readable_type  = '#{readable_parent.name}'
               AND #{ReadMark.quoted_table_name}.readable_id    = #{quoted_table_name}.#{quoted_primary_key}
               AND #{ReadMark.quoted_table_name}.reader_id      = #{quote_bound_value(reader.id)}
               AND #{ReadMark.quoted_table_name}.reader_type    = #{quote_bound_value(reader.class.base_class.name)}
               AND #{ReadMark.quoted_table_name}.timestamp     >= #{quoted_table_name}.#{connection.quote_column_name(readable_options[:on])}"
      end

      def unread_by(reader)
        result = join_read_marks(reader)

        if global_time_stamp = reader.read_mark_global(self).try(:timestamp)
          result.where("#{ReadMark.quoted_table_name}.id IS NULL
                        AND #{quoted_table_name}.#{connection.quote_column_name(readable_options[:on])} > ?", global_time_stamp)
        else
          result.where("#{ReadMark.quoted_table_name}.id IS NULL")
        end
      end

      def read_by(reader)
        result = join_read_marks(reader)

        if global_time_stamp = reader.read_mark_global(self).try(:timestamp)
          result.where("#{ReadMark.quoted_table_name}.id IS NOT NULL
                        OR #{quoted_table_name}.#{connection.quote_column_name(readable_options[:on])} <= ?", global_time_stamp)
        else
          result.where("#{ReadMark.quoted_table_name}.id IS NOT NULL")
        end
      end

      def with_read_marks_for(reader)
        postgresql_string_cast = using_postgresql? ? '::varchar' : ''

        join_read_marks(reader).select("#{quoted_table_name}.*,
                                        #{ReadMark.quoted_table_name}.id AS read_mark_id,
                                        #{quote_bound_value(reader.class.base_class.name)}#{postgresql_string_cast} AS read_mark_reader_type,
                                        #{quote_bound_value(reader.id)} AS read_mark_reader_id")
      end
    end
  end
end
