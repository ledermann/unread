class Reader < ActiveRecord::Base
  self.primary_key = 'number'

  scope :not_foo, -> { where.not(:name => 'foo') }
  scope :not_bar, -> { where.not(:name => 'bar') }

  acts_as_reader :scopes => [:not_foo, :not_bar]
end
