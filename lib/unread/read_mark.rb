class ReadMark < ActiveRecord::Base
  # A global read mark has no readable, so both associations must be optional.
  # The model is loaded before the app config is applied, so be explicit here.
  belongs_to :readable, polymorphic: true, inverse_of: :read_marks, optional: true
  belongs_to :reader, polymorphic: true, inverse_of: :read_marks, optional: true

  validates :reader_id, :reader_type, :readable_type, presence: true

  scope :global, -> { where(readable_id: nil) }
  scope :single, -> { where.not(readable_id: nil) }
  scope :older_than, ->(timestamp) { where(timestamp: ...timestamp) }

  # Classes defined by acts_as_reader
  class_attribute :reader_classes, default: []

  # Classes defined by acts_as_readable
  class_attribute :readable_classes, default: []
end
