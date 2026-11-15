module Unread
  # Helpers for the gem itself. They are not part of the public API.
  module Internal # :nodoc:
    module_function

    # The class that called acts_as_readable, also for STI subclasses
    def readable_parent(klass)
      klass.ancestors.find { |ancestor| ReadMark.readable_classes.include?(ancestor) }
    end

    def assert_reader_class!
      raise 'There is no class using acts_as_reader.' if ReadMark.reader_classes.empty?
    end

    def assert_reader!(reader)
      assert_reader_class!

      unless ReadMark.reader_classes.any? { |klass| reader.is_a?(klass) }
        raise ArgumentError, "Class #{reader.class.name} is not registered by acts_as_reader."
      end
      raise ArgumentError, 'The given reader has no id.' unless reader.id
    end

    def assert_readable!(readable)
      unless readable.respond_to?(:mark_as_read!)
        raise ArgumentError, "Class #{readable.class} is not registered by acts_as_readable."
      end

      raise ArgumentError, "The given #{readable.class} has no id." unless readable.id
    end
  end
end
