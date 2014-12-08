module Unread
  module Reader
    module ClassMethods
      def assert_readable(readable)
        assert_readable_class

        raise ArgumentError, "Class #{readable.class.name} is not registered by acts_as_readable!" unless ReadMark.readable_classes.include?(readable.class)
        raise ArgumentError, "The given #{readable.class.name} has no id!" unless readable.id
      end

      def assert_readable_class
        raise RuntimeError, 'There is no class using acts_as_readable!' unless ReadMark.readable_classes.try(:any?)
      end
    end

    module InstanceMethods
      def read_mark_global(klass)
        instance_var_name = "@read_mark_global_#{klass.name.gsub('::','_')}"
        if instance_variables.include?(instance_var_name.to_sym)
          instance_variable_get(instance_var_name)
        else # memoize
          obj = self.read_marks.where(:readable_type => klass.base_class.name).global.first
          instance_variable_set(instance_var_name, obj)
        end
      end

      def have_not_read?(readable)
        if self.respond_to?(:read_mark_id)
          # For use with scope "with_read_marks_for"
          self.read_mark_id.nil?
        else
          !!self.class.have_not_read(readable).exists?(self) # Rails4 does not return true/false, but nil/count instead.
        end
      end
    end
  end
end