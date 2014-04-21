require 'rails/generators'
require 'rails/generators/migration'

module Unread
  class MigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    desc "Generates migration for read_markers"
    source_root File.expand_path('../templates', __FILE__)

    def create_migration_file
      migration_template 'migration.rb', 'db/migrate/unread_migration.rb'
    end

    def self.next_migration_number(dirname)
      if ActiveRecord::Base.timestamped_migrations
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end
  end
end
