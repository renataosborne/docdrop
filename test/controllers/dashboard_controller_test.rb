require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when signed out" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "greets the signed-in user" do
    sign_in_as users(:one)

    get root_path

    assert_response :success
    assert_select "h1", "Hi, Alex"
    assert_select "#current-user", "Alex Requester"
  end
end
