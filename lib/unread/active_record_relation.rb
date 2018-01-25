module ActiveRecordRelation
  module Unread
    def mark_as_read!(options)
      klass.mark_as_read!(self, options)
    end
  end
end
