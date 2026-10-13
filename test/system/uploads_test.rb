require "application_system_test_case"

class UploadsTest < ApplicationSystemTestCase
  test "a client uploads through the private link and the requester sees the file" do
    request = document_requests(:rental)

    # The client needs no account: just the link.
    visit upload_path(request.upload_token)
    assert_text "Alex Requester has requested documents"
    assert_text "1 of 2 documents received"

    # Picking a file uploads it straight away.
    within("#upload_checklist_item_#{checklist_items(:rental_address).id}") do
      assert_button "Upload Proof of address"
      attach_file "Choose files for Proof of address", file_fixture("payslip.pdf"), make_visible: true
      assert_text "Uploaded: payslip.pdf"
    end
    assert_text "All done, thank you!"

    # A file that only pretends to be a PDF is turned away.
    within("#upload_checklist_item_#{checklist_items(:rental_id).id}") do
      attach_file "Choose files for Photo ID", file_fixture("not-really.pdf"), make_visible: true
      assert_text "isn't a PDF, JPG, PNG, HEIC or WebP file"
    end

    # The requester sees the upload on their side.
    visit new_session_path
    fill_in "Email", with: users(:one).email_address
    fill_in "Password", with: "password"
    click_on "Sign in"
    click_on request.title

    assert_field "Upload link", with: upload_url(request.upload_token)
    within("#checklist") { assert_link "payslip.pdf" }
    assert_text "2 of 2 received"
  end

  test "turning the link off blocks the client" do
    request = document_requests(:rental)

    visit new_session_path
    fill_in "Email", with: users(:one).email_address
    fill_in "Password", with: "password"
    click_on "Sign in"
    click_on request.title
    click_on "Turn off link"
    assert_text "Upload link turned off."

    visit upload_path(request.upload_token)
    assert_text "This upload link isn't available"
  end
end
