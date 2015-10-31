class Customer < ActiveRecord::Base
end

class StiReader < Customer
  acts_as_reader
end
