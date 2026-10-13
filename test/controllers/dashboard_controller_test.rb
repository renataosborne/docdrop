require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when signed out" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "greets the signed-in user and shows only their requests" do
    sign_in_as users(:one)

    get root_path

    assert_response :success
    assert_select "h1", "Hi, Alex"
    assert_select "#current-user", "Alex Requester"
    assert_select "#filter-all", /2/
    assert_select "#filter-pending", /1/
    assert_select "#filter-complete", /1/
    assert_select "#document_requests li", 2
    assert_select "#document_requests", text: /Someone else's request/, count: 0
  end

  test "filters by status" do
    sign_in_as users(:one)

    get root_path(status: "complete")

    assert_select "#document_requests li", 1
    assert_select "#document_requests h3", "Visa paperwork"
    assert_select "#filter-complete[aria-current=page]"
  end

  test "ignores unknown filters" do
    sign_in_as users(:one)
    get root_path(status: "bogus")
    assert_select "#document_requests li", 2
  end

  test "empty state for a new requester" do
    user = User.create!(name: "New Person", email_address: "new@example.com", password: "long-enough")
    sign_in_as user

    get root_path

    assert_select "h2", "No document requests yet"
  end
end
