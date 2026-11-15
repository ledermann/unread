require 'generators/unread/migration/migration_generator'

RSpec.describe Unread::MigrationGenerator do
  let(:destination) { Dir.mktmpdir }

  after { FileUtils.rm_rf(destination) }

  it 'creates the migration' do
    described_class.start(['--quiet'], destination_root: destination)

    migrations = Dir[File.join(destination, 'db/migrate/*_unread_migration.rb')]
    expect(migrations.size).to eq 1
    expect(File.read(migrations.first)).to include(
      "class UnreadMigration < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]",
    )
  end
end
