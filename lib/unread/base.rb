module Unread
  module Base
    def acts_as_reader
      return if ReadMark.reader_classes.include?(self)

      has_many :read_marks, dependent: :delete_all, as: :reader, inverse_of: :reader

      after_create :setup_new_reader

      ReadMark.reader_classes << self

      include Reader::InstanceMethods
      extend Reader::Scopes
    end

    def acts_as_readable(options = {})
      return if ReadMark.readable_classes.include?(self)

      class_attribute :readable_options, default: options.reverse_merge(on: :updated_at)

      has_many :read_marks, as: :readable, dependent: :delete_all, inverse_of: :readable

      ReadMark.readable_classes << self

      include Readable::InstanceMethods
      extend Readable::ClassMethods
      extend Readable::Scopes
    end
  end
end
