module Unread
  module Reader
    module InstanceMethods
      def read_mark_global(klass)
        instance_var_name = "@read_mark_global_#{klass.name.gsub('::','_')}"
        instance_variable_get(instance_var_name) || begin # memoize
          obj = self.read_marks.where(:readable_type => klass.base_class.name).global.first
          instance_variable_set(instance_var_name, obj)
        end
      end
    end
  end
end