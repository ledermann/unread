require 'rails/generators'
require 'rails/generators/migration'
require 'generators/unread/generator_helper'

module Unread
  class PostgresqlUniqueConstraintMigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    extend Unread::Generators::GeneratorHelper

    desc "Generates update migration to add unique constraint for PostgresSQL database"
    source_root File.expand_path('../templates', __FILE__)

    def create_migration_file
      migration_template 'unread_postgresql_unique_constraint_migration.rb', 'db/migrate/unread_postgresql_unique_constraint_migration.rb'
    end
  end
end
