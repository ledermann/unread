class AddReadAtToReadMark < Unread::MIGRATION_BASE_CLASS
  def self.up
    add_column :read_marks, :read_at, :datetime
  end

  def self.down
    remove_column :read_marks, :read_at
  end
end
