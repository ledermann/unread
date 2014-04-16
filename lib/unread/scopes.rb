module Unread
  module Readable
    module Scopes
      def join_read_marks(user)
        assert_reader(user)

        joins "LEFT JOIN read_marks ON read_marks.readable_type  = '#{base_class.name}'
                                   AND read_marks.readable_id    = #{table_name}.#{primary_key}
                                   AND read_marks.user_id        = #{user.id}
                                   AND read_marks.timestamp     >= #{table_name}.#{readable_options[:on]}"
      end

      def unread_by(user)
        result = join_read_marks(user).
                 where('read_marks.id IS NULL')

        if global_time_stamp = user.read_mark_global(self).try(:timestamp)
          result = result.where("#{table_name}.#{readable_options[:on]} > '#{global_time_stamp.to_s(:db)}'")
        end

        result
      end

      def with_read_marks_for(user)
        join_read_marks(user).select("#{table_name}.*, read_marks.id AS read_mark_id")
      end

      # To be used when other eager_loading is done
      def with_read_marks_eager_loaded_for(user)
        eager_load(:read_marks)
          .where("read_marks.user_id = #{user.id} OR read_marks.user_id IS NULL")
          .where("read_marks.timestamp >= #{table_name}.#{readable_options[:on]} OR read_marks.user_id IS NULL")
      end
    end
  end
end
