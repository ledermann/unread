class UnreadMigration < ActiveRecord::Migration
  def self.up
    create_table :read_marks, force: true do |t|
      t.references :readable, polymorphic: { null: false }
      t.references :user,     polymorphic: { null: false }
      t.datetime :timestamp
    end

    add_index :read_marks, [:user_id, :user_type, :readable_type, :readable_id], name: 'read_marks_user_readable_index'
  end

  def self.down
    drop_table :read_marks
  end
end
