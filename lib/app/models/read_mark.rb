class ReadMark < ActiveRecord::Base
  belongs_to :readable, :polymorphic => true
  attr_accessible :readable_id, :user_id, :readable_type, :timestamp

  validates_presence_of :user_id, :readable_type

  scope :global, where(:readable_id => nil)
  scope :single, where('readable_id IS NOT NULL')
  scope :readable_type, lambda { |readable_type | where(:readable_type => readable_type) }
  scope :user,          lambda { |user|           where(:user_id => user.id) }
  scope :older_than,    lambda { |timestamp|      where([ 'timestamp < ?', timestamp]) }

  # Returns the class defined by ActsAsReadable::acts_as_reader
  def self.reader_class
    reflect_on_all_associations(:belongs_to).find { |assoc| assoc.name == :user }.try(:klass)
  end

  class_attribute :readable_classes
end
