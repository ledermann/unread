module Database
  MIGRATION_TEMPLATE = File.expand_path('../../lib/generators/unread/migration/templates/migration.rb.tt', __dir__)

  module_function

  def setup
    database_yml = File.read(File.expand_path('../database.yml', __dir__))
    ActiveRecord::Base.configurations = YAML.safe_load(ERB.new(database_yml).result)
    ActiveRecord::Base.establish_connection(adapter_name.to_sym)
    ActiveRecord.default_timezone = :utc
    ActiveRecord::Migration.verbose = false

    warn "Testing with ActiveRecord #{ActiveRecord.version} on #{adapter_name}"

    load_unread_migration
    ActiveRecord::Base.with_connection { |connection| connection.drop_table(:read_marks, if_exists: true) }
    UnreadMigration.migrate(:up)
    create_spec_tables
  end

  def teardown
    UnreadMigration.migrate(:down)
  end

  def clear
    [ReadMark, Reader, DifferentReader, Customer, Document].each(&:delete_all)
  end

  def adapter_name
    ENV.fetch('DB', 'sqlite')
  end

  # Use the same migration as the generator does
  def load_unread_migration
    eval(ERB.new(File.read(MIGRATION_TEMPLATE)).result, TOPLEVEL_BINDING, MIGRATION_TEMPLATE) # rubocop:disable Security/Eval
  end

  def create_spec_tables
    ActiveRecord::Schema.define do
      create_table :readers, primary_key: 'number', force: true do |t|
        t.string :name
      end

      create_table :different_readers, primary_key: 'number', force: true do |t|
        t.string :name
      end

      create_table :customers, force: true do |t|
        t.string :type
      end

      create_table :documents, primary_key: 'uid', force: true do |t|
        t.string :type
        t.string :subject
        t.text :content
        t.timestamps
      end
    end
  end
end
