module Unread
  def self.included(base)
    base.extend Base
  end

  module Base
    def acts_as_reader
      unless ReadMark.reflections.include?(:reader)
        ReadMark.belongs_to :reader, :polymorphic => true, inverse_of: :read_marks
      end

      has_many :read_marks, :dependent => :delete_all, as: :reader, :inverse_of => :reader

      after_create :setup_new_reader

      ReadMark.reader_classes ||= []
      ReadMark.reader_classes << self

      include Reader::InstanceMethods
      extend Reader::ClassMethods
      extend Reader::Scopes
    end

    def acts_as_readable(options={})
      class_attribute :readable_options

      options.reverse_merge!(:on => :updated_at)
      self.readable_options = options

      has_many :read_marks, :as => :readable, :dependent => :delete_all, inverse_of: :readable

      ReadMark.readable_classes ||= []
      ReadMark.readable_classes << self unless ReadMark.readable_classes.include?(self)

      include Readable::InstanceMethods
      extend Readable::ClassMethods
      extend Readable::Scopes
    end

    def using_postgresql?
      connection.adapter_name.match(/postgres/i)
    end
  end
end
