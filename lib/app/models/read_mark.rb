class ReadMark < ActiveRecord::Base
  belongs_to :readable, :polymorphic => true
  attr_accessible :readable_id, :user_id, :readable_type, :timestamp
  
  validates_presence_of :user_id, :readable_type
  
  scope_method = ActiveRecord::VERSION::MAJOR < 3 ? :named_scope : :scope
  
  send scope_method, :global, :conditions => { :readable_id => nil }
  send scope_method, :single, :conditions => 'readable_id IS NOT NULL'
  send scope_method, :readable_type, lambda { |readable_type | { :conditions => { :readable_type => readable_type }}}
  send scope_method, :user,          lambda { |user|           { :conditions => { :user_id => user.id }}}
  send scope_method, :older_than,    lambda { |timestamp|      { :conditions => [ 'timestamp < ?', timestamp] }}

  # Returns the class defined by ActsAsReadable::acts_as_reader
  def self.reader_class
    user_association = reflect_on_all_associations(:belongs_to).find { |assoc| assoc.name == :user }
    user_association.try(:klass)
  end
  
  if respond_to?(:class_attribute)
    class_attribute :readable_classes
  else
    class_inheritable_accessor :readable_classes
  end
end