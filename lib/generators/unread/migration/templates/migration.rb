class UnreadMigration < ActiveRecord::Migration
  def self.up
    create_table ReadMark, force: true do |t|
      t.references :readable, polymorphic: { null: false }
      t.references :reader,   polymorphic: { null: false }
      t.datetime :timestamp
    end

    add_index ReadMark, [:reader_id, :reader_type, :readable_type, :readable_id], name: 'read_marks_reader_readable_index', unique: true
  end

  def self.down
    drop_table ReadMark
  end
end
