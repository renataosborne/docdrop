require "test_helper"

class FilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @item = checklist_items(:rental_address)
    @item.submit_files([ file_fixture_upload("payslip.pdf", "application/pdf") ])
    @file = @item.files.first
  end

  def file_path_for(item = @item, file = @file)
    document_request_checklist_item_file_path(item.document_request, item, file)
  end

  test "the requester can download their client's file" do
    sign_in_as users(:one)

    get file_path_for

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_match "attachment", response.headers["Content-Disposition"]
    assert_equal file_fixture("payslip.pdf").binread, response.body
  end

  test "signed-out visitors are sent to sign in" do
    get file_path_for
    assert_redirected_to new_session_path
  end

  test "another requester gets not found" do
    sign_in_as users(:two)
    get file_path_for
    assert_response :not_found
  end

  test "public Active Storage blob routes are switched off" do
    assert_not Rails.application.routes.url_helpers.respond_to?(:rails_blob_path)
  end
end
