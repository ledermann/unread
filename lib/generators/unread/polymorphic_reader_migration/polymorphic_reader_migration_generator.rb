require 'rails/generators'
require 'rails/generators/migration'

module Unread
  class PolymorphicReaderMigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    desc "Generates update migration to make reader of read_markers polymorphic"
    source_root File.expand_path('../templates', __FILE__)

    def create_migration_file
      migration_template 'unread_polymorphic_reader_migration.rb', 'db/migrate/unread_polymorphic_reader_migration.rb'
    end

    def self.next_migration_number(dirname)
      if self.timestamped_migrations?
        Time.now.utc.strftime('%Y%m%d%H%M%S')
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end

    def self.timestamped_migrations?
      (
        ActiveRecord::Base.respond_to?(:timestamped_migrations) &&
          ActiveRecord::Base.timestamped_migrations
      ) ||
        (
          ActiveRecord.respond_to?(:timestamped_migrations) &&
            ActiveRecord.timestamped_migrations
        )
    end
  end
end
