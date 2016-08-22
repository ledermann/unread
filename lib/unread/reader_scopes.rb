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

        joins "LEFT JOIN #{ReadMark.quoted_table_name}
                ON #{ReadMark.quoted_table_name}.readable_type  = '#{readable.class.readable_parent.name}'
               AND (#{ReadMark.quoted_table_name}.readable_id   = #{readable.id} OR #{ReadMark.quoted_table_name}.readable_id IS NULL)
               AND #{ReadMark.quoted_table_name}.reader_id      = #{quoted_table_name}.#{quoted_primary_key}
               AND #{ReadMark.quoted_table_name}.reader_type    = '#{connection.quote_string base_class.name}'
               AND #{ReadMark.quoted_table_name}.timestamp     >= '#{connection.quoted_date readable.send(readable.class.readable_options[:on])}'"
      end

      def have_not_read(readable)
        join_read_marks(readable).where("#{ReadMark.quoted_table_name}.id IS NULL")
      end

      def have_read(readable)
        join_read_marks(readable).where("#{ReadMark.quoted_table_name}.id IS NOT NULL")
      end

      def with_read_marks_for(readable)
        postgresql_string_cast = using_postgresql? ? '::varchar' : ''

        join_read_marks(readable).select("#{quoted_table_name}.*,
                                          #{ReadMark.quoted_table_name}.id AS read_mark_id,
                                          #{quote_bound_value readable.class.name}#{postgresql_string_cast} AS read_mark_readable_type,
                                          #{readable.id} AS read_mark_readable_id")
      end
    end
  end
end
