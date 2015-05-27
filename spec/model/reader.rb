class Reader < ActiveRecord::Base
  self.primary_key = 'number'

  scope :not_foo, -> { where('name <> "foo"') }
  scope :not_bar, -> { where('name <> "bar"') }

  acts_as_reader :scope => -> { not_foo.not_bar }
end
