require 'generators/unread/migration/migration_generator'

RSpec.describe Unread::MigrationGenerator do
  let(:destination) { Dir.mktmpdir }
  let(:migrations) { Dir[File.join(destination, 'db/migrate/*_unread_migration.rb')] }
  let(:migration) { File.read(migrations.first) }

  after { FileUtils.rm_rf(destination) }

  it 'creates the migration' do
    described_class.start(['--quiet'], destination_root: destination)

    expect(migrations.size).to eq 1
    expect(migration).to include(
      "class UnreadMigration < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]",
    )
    expect(migration).not_to include('type: :uuid')
  end

  it 'uses the given primary key type' do
    described_class.start(['--quiet', '--primary-key-type=uuid'], destination_root: destination)

    expect(migration).to include('t.references :readable, polymorphic: { null: false }, type: :uuid')
    expect(migration).to include('t.references :reader, polymorphic: true, null: false, type: :uuid')
  end
end
