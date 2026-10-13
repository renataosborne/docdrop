class CreateDocumentRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :document_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :client_name, null: false
      t.string :client_email, null: false
      t.date :due_on
      t.text :message

      t.timestamps
    end
    add_index :document_requests, [ :user_id, :created_at ]
  end
end
