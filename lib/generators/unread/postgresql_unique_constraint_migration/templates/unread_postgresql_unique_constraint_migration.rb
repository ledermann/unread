require 'generators/unread/migration_helper'

class UnreadPostgresqlUniqueConstraintMigration < Unread::MIGRATION_BASE_CLASS
  extend Unread::Generators::MigrationHelper

  INDEX_NAME = 'read_marks_reader_readable_index'
  INDEX_COLUMNS = [:reader_id, :reader_type, :readable_type, :readable_id]

  def self.up
    if postgresql_9_5?
      unless index_exists?(ReadMark, INDEX_COLUMNS, unique: true)
        add_index ReadMark, INDEX_COLUMNS, name: INDEX_NAME, unique: true
      end

      execute <<-SQL
        ALTER TABLE #{ReadMark.table_name}
          ADD CONSTRAINT read_marks_reader_readable_constraint UNIQUE USING INDEX #{INDEX_NAME}
      SQL
    end
  end

  def self.down
    if postgresql_9_5?
      execute <<-SQL
        ALTER TABLE #{ReadMark.table_name}
          DROP CONSTRAINT IF EXISTS read_marks_reader_readable_constraint
      SQL
      add_index ReadMark, INDEX_COLUMNS, name: INDEX_NAME, unique: true
    end
  end
end
