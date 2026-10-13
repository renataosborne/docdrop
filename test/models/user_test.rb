require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attributes)
    User.new({ name: "Jamie Doe", email_address: "jamie@example.com", password: "long-enough" }.merge(attributes))
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "squishes extra whitespace in name" do
    assert_equal "Jamie Doe", build_user(name: "  Jamie   Doe ").name
  end

  test "valid with name, email and long enough password" do
    assert build_user.valid?
  end

  test "requires a name" do
    assert_not build_user(name: "").valid?
  end

  test "requires a well-formed email address" do
    assert_not build_user(email_address: "not-an-email").valid?
  end

  test "requires a unique email address, ignoring case" do
    user = build_user(email_address: users(:one).email_address.upcase)
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "requires a password of at least 8 characters" do
    assert_not build_user(password: "short").valid?
  end

  test "first_name returns the first word of the name" do
    assert_equal "Alex", users(:one).first_name
  end
end
