class UploadsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 30, within: 10.minutes, only: :create, with: -> { head :too_many_requests }

  before_action :set_document_request
  layout "upload"

  def show
  end

  def create
    @checklist_item = @document_request.checklist_items.find(params[:checklist_item_id])

    if @checklist_item.submit_files(params.dig(:checklist_item, :files))
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to upload_path(params[:token]), notice: "Thanks! #{@checklist_item.name} uploaded." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to upload_path(params[:token]), alert: @checklist_item.errors.full_messages_for(:files).to_sentence }
      end
    end
  end

  private
    def set_document_request
      @document_request = DocumentRequest.includes(:user, checklist_items: { files_attachments: :blob })
        .find_by_active_upload_token(params[:token])

      render :unavailable, status: :not_found unless @document_request
    end
end
