class ReadMark < ActiveRecord::Base
  belongs_to :readable, :polymorphic => true
  if ActiveRecord::VERSION::MAJOR < 4
    attr_accessible :readable_id, :user_id, :readable_type, :timestamp
  end

  validates_presence_of :user_id, :readable_type

  scope :global, lambda { where(:readable_id => nil) }
  scope :single, lambda { where('readable_id IS NOT NULL') }
  scope :older_than, lambda { |timestamp| where([ 'timestamp < ?', timestamp ]) }

  # Returns the class defined by acts_as_reader
  class_attribute :reader_class
  class_attribute :reader_options

  # Returns the classes defined by acts_as_readable
  class_attribute :readable_classes

  def self.reader_scope
    result = reader_class

    Array(reader_options[:scopes]).each do |scope|
      result = result.send(scope)
    end
    result
  end
end
