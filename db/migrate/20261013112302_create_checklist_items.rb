class CreateChecklistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :checklist_items do |t|
      t.references :document_request, null: false, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: "pending"
      t.integer :position, null: false, default: 0
      t.datetime :received_at

      t.timestamps
    end
    add_index :checklist_items, [ :document_request_id, :position ]
    add_index :checklist_items, [ :document_request_id, :status ]
  end
end
