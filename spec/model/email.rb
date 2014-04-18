class Email < ActiveRecord::Base
  self.primary_key = 'messageid'
  acts_as_readable :on => :updated_at
end
