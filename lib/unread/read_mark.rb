class ReadMark < ActiveRecord::Base
  belongs_to :readable, :polymorphic => true

  validates_presence_of :reader_id, :reader_type, :readable_type

  scope :global, lambda { where(:readable_id => nil) }
  scope :single, lambda { where('readable_id IS NOT NULL') }
  scope :older_than, lambda { |timestamp| where([ 'timestamp < ?', timestamp ]) }

  # Returns the class and options defined by acts_as_reader
  class_attribute :reader_classes
  class_attribute :reader_options

  # Returns the classes defined by acts_as_readable
  class_attribute :readable_classes

  def self.reader_scope(klass)
    reader_options[klass][:scope].try(:call) || klass
  end
end
