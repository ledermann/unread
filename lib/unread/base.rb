module Unread
  def self.included(base)
    base.extend Base
  end

  module Base
    def acts_as_reader(options={})
      ReadMark.belongs_to :user, :class_name => self.to_s

      has_many :read_marks, :dependent => :delete_all, :foreign_key => 'user_id', :inverse_of => :user

      after_create do |user|
        # We assume that a new user should not be tackled by tons of old messages
        # created BEFORE he signed up.
        # Instead, the new user starts with zero unread messages
        (ReadMark.readable_classes || []).each do |klass|
          klass.mark_as_read! :all, :for => user
        end
      end

      ReadMark.reader_class = self
      ReadMark.reader_options = options

      include Reader::InstanceMethods
      extend Reader::ClassMethods
      extend Reader::Scopes
    end

    def acts_as_readable(options={})
      class_attribute :readable_options

      options.reverse_merge!(:on => :updated_at)
      self.readable_options = options

      has_many :read_marks, :as => :readable, :dependent => :delete_all

      ReadMark.readable_classes ||= []
      ReadMark.readable_classes << self unless ReadMark.readable_classes.include?(self)

      include Readable::InstanceMethods
      extend Readable::ClassMethods
      extend Readable::Scopes
    end
  end
end
