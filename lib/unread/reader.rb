module Unread
  module Reader
    module InstanceMethods
      def read_mark_global(klass)
        @read_mark_global ||= {}
        @read_mark_global[klass] ||= read_marks.where(:readable_type => klass.base_class.name).global.first
      end

      def forget_memoized_read_mark_global
        @read_mark_global = nil
      end
    end
  end
end