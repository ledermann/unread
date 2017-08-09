class UnreadMigration < Unread::MIGRATION_BASE_CLASS
  def self.up
    create_table :read_marks, force: true, options: create_options do |t|
      t.references :readable, polymorphic: { null: false }
      t.references :reader,   polymorphic: { null: false }
      t.datetime :timestamp
    end

    add_index :read_marks, [:reader_id, :reader_type, :readable_type, :readable_id], name: 'read_marks_reader_readable_index', unique: true
  end

  def self.down
    drop_table :read_marks
  end

  def self.create_options
    options = ''
    if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter) \
      && ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
      options = 'DEFAULT CHARSET=latin1'
    end
    options
  end
end
