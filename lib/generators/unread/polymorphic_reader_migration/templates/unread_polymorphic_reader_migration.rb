class UnreadPolymorphicReaderMigration < Unread::MIGRATION_BASE_CLASS
  def self.up
    remove_index :read_marks, [:user_id, :readable_type, :readable_id]
    rename_column :read_marks, :user_id, :reader_id
    add_column :read_marks, :reader_type, :string
    execute "update read_marks set reader_type = 'User'"
    add_index :read_marks, [:reader_id, :reader_type, :readable_type, :readable_id], name: 'read_marks_reader_readable_index', unique: true
  end

  def self.down
    remove_index :read_marks, name: 'read_marks_reader_readable_index'
    remove_column :read_marks, :reader_type
    rename_column :read_marks, :reader_id, :user_id
    add_index :read_marks, [:user_id, :readable_type, :readable_id]
  end
end
