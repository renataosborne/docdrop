class UploadLinksController < ApplicationController
  before_action :set_document_request

  def enable
    @document_request.enable_upload_link!
    redirect_to @document_request, notice: "Upload link is on and valid for 30 days."
  end

  def disable
    @document_request.disable_upload_link!
    redirect_to @document_request, notice: "Upload link turned off. Your client can't upload until you turn it back on."
  end

  def reset
    @document_request.reset_upload_link!
    redirect_to @document_request, notice: "New upload link created. The old link no longer works."
  end

  private
    def set_document_request
      @document_request = Current.user.document_requests.find(params[:document_request_id])
    end
end
