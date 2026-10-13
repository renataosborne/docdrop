class ChecklistItemsController < ApplicationController
  def update
    @document_request = Current.user.document_requests.find(params[:document_request_id])
    @checklist_item = @document_request.checklist_items.find(params[:id])
    @checklist_item.update!(params.expect(checklist_item: [ :status ]))

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @document_request }
    end
  end
end
