class DocumentRequestsController < ApplicationController
  before_action :set_document_request, only: %i[ show edit update destroy ]

  def show
  end

  def new
    @document_request = Current.user.document_requests.new
    @document_request.checklist_items.build
  end

  def create
    @document_request = Current.user.document_requests.new(document_request_params)

    if @document_request.save
      redirect_to @document_request, notice: "Request created for #{@document_request.client_name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @document_request.update(document_request_params)
      redirect_to @document_request, notice: "Request updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document_request.destroy!
    redirect_to root_path, notice: "Request deleted.", status: :see_other
  end

  private
    # Scoping through the current user means another requester's request is a 404, never visible.
    def set_document_request
      @document_request = Current.user.document_requests.includes(:checklist_items).find(params[:id])
    end

    def document_request_params
      params.expect(document_request: [
        :title, :client_name, :client_email, :due_on, :message,
        checklist_items_attributes: [ [ :id, :name, :_destroy ] ]
      ])
    end
end
