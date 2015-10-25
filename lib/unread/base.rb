module Unread
  def self.included(base)
    base.extend Base
  end

  module Base
    def acts_as_reader(options={})
      unless ReadMark.reflections.include?(:user)
        ReadMark.belongs_to :user, :polymorphic => true, inverse_of: :read_marks
      end

      has_many :read_marks, :dependent => :delete_all, as: :user, :inverse_of => :user

      after_create do |user|
        # We assume that a new user should not be tackled by tons of old messages
        # created BEFORE he signed up.
        # Instead, the new user starts with zero unread messages
        (ReadMark.readable_classes || []).each do |klass|
          klass.mark_as_read! :all, :for => user
        end
      end

      ReadMark.reader_classes ||= []
      ReadMark.reader_options ||= {}
      ReadMark.reader_classes << self
      ReadMark.reader_options[self] = options

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
  end
end
