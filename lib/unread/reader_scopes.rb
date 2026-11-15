module Unread
  module Reader
    module Scopes
      # This class method may be overridden to restrict readers to a subset of records.
      # It must return self or an ActiveRecord::Relation
      def reader_scope
        self
      end

      def have_not_read(readable)
        join_read_marks(readable).where(ReadMark.table_name => { id: nil })
      end

      def have_read(readable)
        join_read_marks(readable).where.not(ReadMark.table_name => { id: nil })
      end

      def with_read_marks_for(readable)
        join_read_marks(readable).select(sanitize_sql_array([<<~SQL.squish, readable.class.name, readable.id]))
          #{quoted_table_name}.*,
          #{ReadMark.quoted_table_name}.id AS read_mark_id,
          ? AS read_mark_readable_type,
          ? AS read_mark_readable_id
        SQL
      end

      private

      def join_read_marks(readable)
        Internal.assert_readable!(readable)

        read_marks = ReadMark.quoted_table_name
        sql = <<~SQL.squish
          LEFT JOIN #{read_marks}
                 ON #{read_marks}.readable_type = :readable_type
                AND (#{read_marks}.readable_id  = :readable_id OR #{read_marks}.readable_id IS NULL)
                AND #{read_marks}.reader_id     = #{quoted_table_name}.#{quoted_primary_key}
                AND #{read_marks}.reader_type   = :reader_type
                AND #{read_marks}.timestamp    >= :timestamp
        SQL

        binds = {
          readable_type: Internal.readable_parent(readable.class).name,
          readable_id: readable.id,
          reader_type: base_class.name,
          timestamp: readable.public_send(readable.class.readable_options[:on]),
        }

        joins sanitize_sql_array([sql, binds])
      end
    end
  end
end
