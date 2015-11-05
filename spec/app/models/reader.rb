class Reader < ActiveRecord::Base
  self.primary_key = 'number'

  scope :not_foo, -> { where("name <> 'foo'") }
  scope :not_bar, -> { where("name <> 'bar'") }

  acts_as_reader

  def self.reader_scope
    not_foo.not_bar
  end
end
