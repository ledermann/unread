class DifferentReader < ActiveRecord::Base
  self.primary_key = 'number'

  acts_as_reader
end
