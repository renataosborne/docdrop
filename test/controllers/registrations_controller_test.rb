require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def valid_params
    { user: { name: "Jamie Doe", email_address: "jamie@example.com", password: "long-enough", password_confirmation: "long-enough" } }
  end

  test "new" do
    get new_registration_path
    assert_response :success
  end

  test "create signs the new user in and goes to the dashboard" do
    assert_difference "User.count", 1 do
      post registration_path, params: valid_params
    end

    assert_redirected_to root_path
    assert cookies[:session_id].present?

    follow_redirect!
    assert_select "h1", "Hi, Jamie"
  end

  test "create with invalid details shows errors and creates no user" do
    invalid = valid_params.deep_merge(user: { email_address: users(:one).email_address, password_confirmation: "different" })

    assert_no_difference "User.count" do
      post registration_path, params: invalid
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation li", text: "Email address has already been taken"
    assert_select "#error_explanation li", text: "Password confirmation doesn't match Password"
  end
end
