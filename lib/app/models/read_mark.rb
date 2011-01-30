class ReadMark < ActiveRecord::Base
  belongs_to :user
  belongs_to :readable, :polymorphic => true
  
  validates_presence_of :user_id, :readable_type
  
  scope_method = ActiveRecord::VERSION::MAJOR == 2 ? :named_scope : :scope
  
  send scope_method, :global, :conditions => { :readable_id => nil }
  send scope_method, :single, :conditions => 'readable_id IS NOT NULL'
  send scope_method, :readable_type, lambda { |readable_type | { :conditions => { :readable_type => readable_type }}}
  send scope_method, :user,          lambda { |user|           { :conditions => { :user_id => user.id }}}
  send scope_method, :older_than,    lambda { |timestamp|      { :conditions => [ 'timestamp < ?', timestamp] }}
  
  class_inheritable_reader :reader_class
  class_inheritable_reader :readable_classes
end