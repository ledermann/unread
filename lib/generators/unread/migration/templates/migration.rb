require 'generators/unread/migration_helper'

class UnreadMigration < Unread::MIGRATION_BASE_CLASS
  extend Unread::Generators::MigrationHelper

  def self.up
    create_table ReadMark, force: true, options: create_options do |t|
      t.references :readable, polymorphic: { null: false }
      t.references :reader,   polymorphic: { null: false }
      t.datetime :timestamp
    end

    index_name = 'read_marks_reader_readable_index'
    add_index ReadMark, [:reader_id, :reader_type, :readable_type, :readable_id], name: index_name, unique: true

    if postgresql_9_5?
      execute <<-SQL
        ALTER TABLE #{ReadMark.table_name}
          ADD CONSTRAINT read_marks_reader_readable_constraint UNIQUE USING INDEX #{index_name}
      SQL
    end
  end

  def self.down
    drop_table ReadMark
  end

  def self.create_options
    mysql? ? 'DEFAULT CHARSET=latin1' : ''
  end
end
