class ReadMark < ActiveRecord::Base
  belongs_to :readable, :polymorphic => true

  validates_presence_of :reader_id, :reader_type, :readable_type

  scope :global, lambda { where(:readable_id => nil) }
  scope :single, lambda { where('readable_id IS NOT NULL') }
  scope :older_than, lambda { |timestamp| where([ 'timestamp < ?', timestamp ]) }

  # Returns the classes defined by acts_as_reader
  class_attribute :reader_classes

  # Returns the classes defined by acts_as_readable
  class_attribute :readable_classes
end
