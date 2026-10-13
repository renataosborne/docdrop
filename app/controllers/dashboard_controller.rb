class DashboardController < ApplicationController
  FILTERS = %w[ all pending complete ].freeze

  def show
    @user = Current.user
    requests = @user.document_requests

    @filter = FILTERS.include?(params[:status]) ? params[:status] : "all"
    @counts = { "all" => requests.count, "pending" => requests.pending.count, "complete" => requests.complete.count }

    scoped = @filter == "all" ? requests : requests.public_send(@filter)
    @document_requests = scoped.includes(:checklist_items).recent_first
  end
end
