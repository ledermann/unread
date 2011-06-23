class ReadMark < ActiveRecord::Base
  belongs_to :user
  belongs_to :readable, :polymorphic => true
  
  validates_presence_of :user_id, :readable_type
  
  scope_method = respond_to?(:scope) ? :scope : :named_scope
  
  send scope_method, :global, :conditions => { :readable_id => nil }
  send scope_method, :single, :conditions => 'readable_id IS NOT NULL'
  send scope_method, :readable_type, lambda { |readable_type | { :conditions => { :readable_type => readable_type }}}
  send scope_method, :user,          lambda { |user|           { :conditions => { :user_id => user.id }}}
  send scope_method, :older_than,    lambda { |timestamp|      { :conditions => [ 'timestamp < ?', timestamp] }}
  
  if respond_to?(:class_attribute)
    class_attribute :reader_class, :readable_classes
  else
    class_inheritable_accessor :reader_class, :readable_classes
  end
end