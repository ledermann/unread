class Document < ActiveRecord::Base
  self.primary_key = 'uid'
  acts_as_readable :on => :updated_at
end
