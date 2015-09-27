module Unread
  module Reader
    module ClassMethods
      def assert_readable(readable)
        unless readable.respond_to?(:mark_as_read!)
          raise ArgumentError, "Class #{readable.class} is not registered by acts_as_readable."
        end

        unless readable.id
          raise ArgumentError, "The given #{readable.class} has no id."
        end
      end
    end

    module InstanceMethods
      def read_mark_global(klass)
        @read_mark_global ||= {}
        @read_mark_global[klass] ||= read_marks.where(:readable_type => klass.base_class.name).global.first
      end

      def forget_memoized_read_mark_global
        @read_mark_global = nil
      end

      def have_read?(readable)
        if self.respond_to?(:read_mark_id) && read_mark_id_belongs_to?(readable)
          # For use with scope "with_read_marks_for"
          !self.read_mark_id.nil?
        else
          !self.class.have_not_read(readable).exists?(self.id)
        end
      end

      private

      def read_mark_id_belongs_to?(readable)
        self.read_mark_readable_type == readable.class.base_class.name &&
        (self.read_mark_readable_id.nil? || self.read_mark_readable_id == readable.id)
      end
    end
  end
end