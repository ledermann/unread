class ReadMark < ActiveRecord::Base
  belongs_to :user
  belongs_to :readable, :polymorphic => true
  
  validates_presence_of :user_id, :readable_type
  
  named_scope :global, :conditions => { :readable_id => nil }
  named_scope :single, :conditions => 'readable_id IS NOT NULL'
  
  class_inheritable_reader :reader_class
  class_inheritable_reader :readable_classes
end