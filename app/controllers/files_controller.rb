# Serves uploaded documents only to the requester who owns them. Active Storage's public
# blob routes are switched off (see config/application.rb), so this is the only way in.
class FilesController < ApplicationController
  def show
    document_request = Current.user.document_requests.find(params[:document_request_id])
    checklist_item = document_request.checklist_items.find(params[:checklist_item_id])
    file = checklist_item.files.find(params[:id])

    send_data file.download, filename: file.filename.to_s, type: file.content_type, disposition: "attachment"
  end
end
