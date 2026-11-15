module Unread
  module Readable
    module Scopes
      def unread_by(reader)
        result = join_read_marks(reader).where(ReadMark.table_name => { id: nil })

        if (global_timestamp = reader.read_mark_global(self)&.timestamp)
          result.where("#{quoted_readable_column} > ?", global_timestamp)
        else
          result
        end
      end

      def read_by(reader)
        result = join_read_marks(reader)
        read_mark_id = "#{ReadMark.quoted_table_name}.id"

        if (global_timestamp = reader.read_mark_global(self)&.timestamp)
          result.where("#{read_mark_id} IS NOT NULL OR #{quoted_readable_column} <= ?", global_timestamp)
        else
          result.where("#{read_mark_id} IS NOT NULL")
        end
      end

      def with_read_marks_for(reader)
        join_read_marks(reader).select(sanitize_sql_array([<<~SQL.squish, reader.class.base_class.name, reader.id]))
          #{quoted_table_name}.*,
          #{ReadMark.quoted_table_name}.id AS read_mark_id,
          ? AS read_mark_reader_type,
          ? AS read_mark_reader_id
        SQL
      end

      private

      def join_read_marks(reader)
        Internal.assert_reader!(reader)

        read_marks = ReadMark.quoted_table_name
        sql = <<~SQL.squish
          LEFT JOIN #{read_marks}
                 ON #{read_marks}.readable_type = :readable_type
                AND #{read_marks}.readable_id   = #{quoted_table_name}.#{quoted_primary_key}
                AND #{read_marks}.reader_id     = :reader_id
                AND #{read_marks}.reader_type   = :reader_type
                AND #{read_marks}.timestamp    >= #{quoted_readable_column}
        SQL

        binds = {
          readable_type: Internal.readable_parent(self).name,
          reader_id: reader.id,
          reader_type: reader.class.base_class.name,
        }

        joins sanitize_sql_array([sql, binds])
      end

      def quoted_readable_column
        "#{quoted_table_name}.#{adapter_class.quote_column_name(readable_options[:on])}"
      end
    end
  end
end
