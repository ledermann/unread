class ReadMark < ActiveRecord::Base
  belongs_to :readable, :polymorphic => true

  validates_presence_of :user_id, :readable_type

  scope :global, where(:readable_id => nil)
  scope :single, where('readable_id IS NOT NULL')
  scope :older_than, lambda { |timestamp| where([ 'timestamp < ?', timestamp]) }

  # Returns the class defined by acts_as_reader
  def self.reader_class
    reflect_on_all_associations(:belongs_to).find { |assoc| assoc.name == :user }.try(:klass)
  end

  class_attribute :readable_classes
end
