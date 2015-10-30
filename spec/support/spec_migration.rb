class SpecMigration < ActiveRecord::Migration
  def self.up
    create_table :readers, :primary_key => 'number', :force => true do |t|
      t.string :name
    end

    create_table :different_readers, :primary_key => 'number', :force => true do |t|
      t.string :name
    end

    create_table :customers, :force => true do |t|
      t.string :type
    end

    create_table :documents, :primary_key => 'uid', :force => true do |t|
      t.string :type
      t.string :subject
      t.text :content
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
