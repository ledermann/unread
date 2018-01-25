require 'rails/generators'
require 'rails/generators/migration'
require 'generators/unread/generator_helper'

module Unread
  class PolymorphicReaderMigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    extend Unread::Generators::GeneratorHelper

    desc "Generates update migration to make reader of read_markers polymorphic"
    source_root File.expand_path('../templates', __FILE__)

    def create_migration_file
      migration_template 'unread_polymorphic_reader_migration.rb', 'db/migrate/unread_polymorphic_reader_migration.rb'
    end
  end
end
