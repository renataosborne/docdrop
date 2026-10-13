require "application_system_test_case"

class DocumentRequestsTest < ApplicationSystemTestCase
  setup do
    visit new_session_path
    fill_in "Email", with: users(:one).email_address
    fill_in "Password", with: "password"
    click_on "Sign in"
    assert_selector "h1", text: "Hi, Alex"
  end

  test "creating a request with a checklist and marking documents received" do
    click_on "+ New request"

    fill_in "Title", with: "Mortgage documents"
    fill_in "Client name", with: "Jo Client"
    fill_in "Client email", with: "jo@example.com"

    within("[data-checklist-form-target=list]") { find("input[type=text]").fill_in with: "Payslip" }
    click_on "+ Add item"
    all("[data-checklist-form-target=list] input[type=text]").last.fill_in with: "Bank statement"
    click_on "+ Add item"
    all("[data-checklist-form-target=list] input[type=text]").last.fill_in with: "Throwaway"
    within(all("[data-checklist-form-target=list] li").last) { click_on "Remove item" }

    click_on "Create request"

    assert_text "Request created for Jo Client."
    assert_selector "#checklist li", count: 2
    assert_text "0 of 2 received"

    click_on "Mark Payslip as received"
    assert_text "1 of 2 received"
    assert_selector "#checklist", text: "Received less than a minute ago"

    click_on "Mark Bank statement as received"
    assert_text "2 of 2 received"
    assert_selector "span", text: "Complete"
  end

  test "editing a request removes an item" do
    visit document_request_path(document_requests(:rental))
    click_on "Edit"

    rows = all("[data-checklist-form-target=list] li")
    within(rows.last) { click_on "Remove item" }
    click_on "Save changes"

    assert_text "Request updated."
    assert_selector "#checklist li", count: 1
  end
end
