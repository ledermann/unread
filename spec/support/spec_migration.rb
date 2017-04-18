class SpecMigration < Unread::MIGRATION_BASE_CLASS
  def self.up
    create_table Reader, :primary_key => 'number', :force => true do |t|
      t.string :name
    end

    create_table DifferentReader, :primary_key => 'number', :force => true do |t|
      t.string :name
    end

    create_table Customer, :force => true do |t|
      t.string :type
    end

    create_table Document, :primary_key => 'uid', :force => true do |t|
      t.string :type
      t.string :subject
      t.text :content
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
