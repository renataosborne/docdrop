require "test_helper"

class UploadLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @request_record = document_requests(:rental)
  end

  test "show page displays the active link" do
    get document_request_path(@request_record)
    assert_select "#upload_link_url[value=?]", upload_url(@request_record.upload_token)
  end

  test "disable and enable" do
    post disable_document_request_upload_link_path(@request_record)
    assert_redirected_to document_request_path(@request_record)
    assert_not @request_record.reload.upload_link_active?

    post enable_document_request_upload_link_path(@request_record)
    assert @request_record.reload.upload_link_active?
  end

  test "reset changes the token" do
    assert_changes -> { @request_record.reload.upload_token } do
      post reset_document_request_upload_link_path(@request_record)
    end
  end

  test "can't manage another requester's link" do
    other = document_requests(:others)

    post disable_document_request_upload_link_path(other)
    assert_response :not_found
    assert other.reload.upload_link_active?
  end

  test "requires sign in" do
    sign_out
    post disable_document_request_upload_link_path(@request_record)
    assert_redirected_to new_session_path
  end
end
