require "test_helper"

class UploadLinkTest < ActiveSupport::TestCase
  setup { @request = document_requests(:rental) }

  test "new requests get a long random token and a 30-day link" do
    request = users(:one).document_requests.create!(
      title: "Docs", client_name: "Jo", client_email: "jo@example.com", checklist_items_attributes: [ { name: "ID" } ]
    )

    assert request.upload_token.length >= 24
    assert_in_delta 30.days.from_now, request.upload_expires_at, 1.minute
    assert request.upload_link_active?
  end

  test "status reflects disabled and expired links" do
    assert_equal :active, @request.upload_link_status

    @request.upload_expires_at = 1.minute.ago
    assert_equal :expired, @request.upload_link_status

    @request.upload_link_enabled = false
    assert_equal :disabled, @request.upload_link_status
  end

  test "find_by_active_upload_token only finds active links" do
    assert_equal @request, DocumentRequest.find_by_active_upload_token(@request.upload_token)
    assert_nil DocumentRequest.find_by_active_upload_token("nope")
    assert_nil DocumentRequest.find_by_active_upload_token("")

    @request.disable_upload_link!
    assert_nil DocumentRequest.find_by_active_upload_token(@request.upload_token)

    @request.update!(upload_link_enabled: true, upload_expires_at: 1.minute.ago)
    assert_nil DocumentRequest.find_by_active_upload_token(@request.upload_token)
  end

  test "enabling renews the link for 30 days" do
    @request.update!(upload_link_enabled: false, upload_expires_at: 1.day.ago)
    @request.enable_upload_link!

    assert @request.upload_link_active?
    assert_in_delta 30.days.from_now, @request.upload_expires_at, 1.minute
  end

  test "resetting issues a new token so the old link stops working" do
    old_token = @request.upload_token
    @request.reset_upload_link!

    assert_not_equal old_token, @request.upload_token
    assert_nil DocumentRequest.find_by_active_upload_token(old_token)
    assert_equal @request, DocumentRequest.find_by_active_upload_token(@request.upload_token)
  end
end
