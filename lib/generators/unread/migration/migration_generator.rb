require 'rails/generators'
require 'rails/generators/active_record'

module Unread
  class MigrationGenerator < Rails::Generators::Base
    include ActiveRecord::Generators::Migration

    desc 'Generates migration for read_marks'
    source_root File.expand_path('templates', __dir__)

    class_option :primary_key_type, type: :string,
                                    desc: 'The type of the reader and readable id columns, for example uuid'

    def create_migration_file
      migration_template 'migration.rb', File.join(db_migrate_path, 'unread_migration.rb')
    end
  end
end
