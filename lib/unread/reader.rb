module Unread
  module Reader
    module InstanceMethods
      # The read mark that marks all items of the given readable class as read
      # up to its timestamp. Memoized, including nil.
      def read_mark_global(klass)
        @read_mark_global ||= {}
        readable_klass = Internal.readable_parent(klass)

        @read_mark_global.fetch(readable_klass) do
          @read_mark_global[readable_klass] = read_marks.where(readable_type: readable_klass.name).global.first
        end
      end

      def have_read?(readable)
        if respond_to?(:read_mark_id) && read_mark_id_belongs_to?(readable)
          # For use with scope "with_read_marks_for"
          !read_mark_id.nil?
        else
          !self.class.have_not_read(readable).exists?(id)
        end
      end

      private

      def forget_memoized_read_mark_global
        @read_mark_global = nil
      end

      def read_mark_id_belongs_to?(readable)
        read_mark_readable_type == readable.class.name &&
          (read_mark_readable_id.nil? || read_mark_readable_id.to_i == readable.id)
      end

      # We assume that a new reader should not be tackled by tons of old messages created BEFORE signing up.
      # Instead, the new reader should start with zero unread messages.
      # If you don't want this, you can override this method in your reader class
      def setup_new_reader
        ReadMark.readable_classes.each do |klass|
          klass.mark_as_read! :all, for: self
        end
      end
    end
  end
end
