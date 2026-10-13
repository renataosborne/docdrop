require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @request_record = document_requests(:rental)
    @item = checklist_items(:rental_address)
  end

  def upload(item = @item, file: "payslip.pdf", type: "application/pdf", token: @request_record.upload_token, **options)
    post upload_item_path(token, item), params: { checklist_item: { files: [ file_fixture_upload(file, type) ] } }, **options
  end

  test "shows the checklist without signing in" do
    get upload_path(@request_record.upload_token)

    assert_response :success
    assert_select "h1", @request_record.title
    assert_select "#upload_checklist li", 2
    assert_select "meta[name=robots][content*=noindex]"
    assert_select "meta[name=referrer][content=no-referrer]"
  end

  test "unknown, disabled and expired links all show the same unavailable page" do
    get upload_path("not-a-real-token")
    assert_response :not_found
    assert_select "h1", "This upload link isn't available"

    @request_record.disable_upload_link!
    get upload_path(@request_record.upload_token)
    assert_response :not_found
    assert_select "h1", "This upload link isn't available"

    @request_record.update!(upload_link_enabled: true, upload_expires_at: 1.minute.ago)
    get upload_path(@request_record.upload_token)
    assert_response :not_found
  end

  test "uploading a file marks the item received and updates the page with turbo streams" do
    upload as: :turbo_stream

    assert_response :success
    assert @item.reload.received?
    assert_equal [ "payslip.pdf" ], @item.files.map { it.filename.to_s }
    assert_select "turbo-stream[action=replace][target=upload_checklist_item_#{@item.id}]"
    assert_select "turbo-stream[target=upload_progress]", text: /All done/
  end

  test "uploading without turbo redirects back with a notice" do
    upload

    assert_redirected_to upload_path(@request_record.upload_token)
    follow_redirect!
    assert_select "#notice", "Thanks! Proof of address uploaded."
  end

  test "a disguised file is rejected with an error" do
    upload file: "not-really.pdf", as: :turbo_stream

    assert_response :unprocessable_entity
    assert_select "turbo-stream template [role=alert]", text: /isn't a PDF, JPG, PNG, HEIC or WebP file/
    assert @item.reload.pending?
  end

  test "can't upload through a link that's been turned off" do
    @request_record.disable_upload_link!
    upload

    assert_response :not_found
    assert_not @item.reload.files.attached?
  end

  test "can't upload to an item that belongs to a different request" do
    upload checklist_items(:others_contract)

    assert_response :not_found
    assert_not checklist_items(:others_contract).files.attached?
  end
end
