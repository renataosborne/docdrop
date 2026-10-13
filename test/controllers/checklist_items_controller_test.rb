require "test_helper"

class ChecklistItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @item = checklist_items(:rental_address)
  end

  test "marks an item received with a turbo stream update" do
    patch document_request_checklist_item_path(@item.document_request, @item),
      params: { checklist_item: { status: "received" } }, as: :turbo_stream

    assert_response :success
    assert @item.reload.received?
    assert_select "turbo-stream[action=replace][target=#{ActionView::RecordIdentifier.dom_id(@item)}]"
    assert_select "turbo-stream[target=progress_document_request_#{@item.document_request_id}]"
  end

  test "falls back to a redirect without turbo" do
    patch document_request_checklist_item_path(@item.document_request, @item), params: { checklist_item: { status: "received" } }
    assert_redirected_to document_request_path(@item.document_request)
  end

  test "can't change another requester's item" do
    other = checklist_items(:others_contract)
    patch document_request_checklist_item_path(other.document_request, other), params: { checklist_item: { status: "received" } }

    assert_response :not_found
    assert other.reload.pending?
  end

  test "can't reach an item through a different request" do
    patch document_request_checklist_item_path(document_requests(:visa), @item), params: { checklist_item: { status: "received" } }
    assert_response :not_found
  end
end
