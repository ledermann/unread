class UnreadMigration < ActiveRecord::Migration
  def change
    create_table :read_marks, :force => true do |t|
      t.integer  :readable_id
      t.integer  :user_id,       :null => false
      t.string   :readable_type, :null => false, :limit => 20
      t.datetime :timestamp
    end

    add_index :read_marks, [:user_id, :readable_type, :readable_id]
  end
end
