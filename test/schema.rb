ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string :name
  end
  
  create_table :emails, :force => true do |t|
    t.string :subject
    t.text :content
    t.datetime :created_at
    t.datetime :updated_at
  end
  
  create_table :read_marks, :force => true do |t|
    t.integer  :readable_id
    t.integer  :user_id,       :null => false
    t.string   :readable_type, :null => false
    t.datetime :timestamp
  end
  add_index :read_marks, [:user_id, :readable_type, :readable_id]
end