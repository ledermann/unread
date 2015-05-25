module Unread
  module Reader
    module ClassMethods
      def assert_readable(readable)
        assert_readable_class

        unless ReadMark.readable_classes.include?(readable.class)
          raise ArgumentError, "Class #{readable.class.name} is not registered by acts_as_readable."
        end
        raise ArgumentError, "The given #{readable.class.name} has no id." unless readable.id
      end

      def assert_readable_class
        raise RuntimeError, 'There is no class using acts_as_readable.' unless ReadMark.readable_classes.try(:any?)
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
        if self.respond_to?(:read_mark_id)
          # For use with scope "with_read_marks_for"
          !self.read_mark_id.nil?
        else
          !self.class.have_not_read(readable).exists?(self.id)
        end
      end
    end
  end
end