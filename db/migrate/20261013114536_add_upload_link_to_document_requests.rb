class AddUploadLinkToDocumentRequests < ActiveRecord::Migration[8.1]
  def up
    add_column :document_requests, :upload_token, :string
    add_column :document_requests, :upload_link_enabled, :boolean, null: false, default: true
    add_column :document_requests, :upload_expires_at, :datetime

    # Give existing requests a random token and a 30-day link before tightening the constraints.
    execute <<~SQL
      UPDATE document_requests
      SET upload_token = replace(gen_random_uuid()::text, '-', ''),
          upload_expires_at = now() + interval '30 days'
    SQL

    change_column_null :document_requests, :upload_token, false
    change_column_null :document_requests, :upload_expires_at, false
    add_index :document_requests, :upload_token, unique: true
  end

  def down
    remove_index :document_requests, :upload_token
    remove_column :document_requests, :upload_expires_at
    remove_column :document_requests, :upload_link_enabled
    remove_column :document_requests, :upload_token
  end
end
