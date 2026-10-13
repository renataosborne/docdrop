require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "a requester signs up, signs out and signs back in" do
    visit root_path
    assert_selector "h1", text: "Sign in"

    click_on "Create an account"
    fill_in "Name", with: "Jamie Doe"
    fill_in "Email", with: "jamie@example.com"
    fill_in "Password", with: "long-enough"
    fill_in "Confirm password", with: "long-enough"
    click_on "Create account"

    assert_text "Welcome to DocDrop, Jamie!"
    assert_selector "h1", text: "Hi, Jamie"

    click_on "Sign out"
    assert_selector "h1", text: "Sign in"

    fill_in "Email", with: "jamie@example.com"
    fill_in "Password", with: "long-enough"
    click_on "Sign in"

    assert_selector "h1", text: "Hi, Jamie"
  end

  test "signing in with a wrong password shows an error" do
    visit new_session_path
    fill_in "Email", with: users(:one).email_address
    fill_in "Password", with: "wrong-password"
    click_on "Sign in"

    assert_text "Try another email address or password."
  end
end
