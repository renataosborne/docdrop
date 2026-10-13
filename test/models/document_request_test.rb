require "test_helper"

class DocumentRequestTest < ActiveSupport::TestCase
  def build_request(**attributes)
    users(:one).document_requests.new({
      title: "Loan documents", client_name: "Jo Client", client_email: "jo@example.com",
      checklist_items_attributes: [ { name: "Payslip" }, { name: "Bank statement" } ]
    }.merge(attributes))
  end

  test "valid with details and at least one checklist item" do
    assert build_request.valid?
  end

  test "requires at least one checklist item" do
    request = build_request(checklist_items_attributes: [])
    assert_not request.valid?
    assert_includes request.errors[:base], "Add at least one document to the checklist"
  end

  test "ignores blank checklist rows" do
    request = build_request(checklist_items_attributes: [ { name: "Payslip" }, { name: "" } ])
    request.save!
    assert_equal [ "Payslip" ], request.checklist_items.map(&:name)
  end

  test "numbers checklist items in the order given" do
    request = build_request
    request.save!
    assert_equal [ [ "Payslip", 1 ], [ "Bank statement", 2 ] ], request.checklist_items.map { [ it.name, it.position ] }
  end

  test "requires a valid client email and normalizes it" do
    assert_not build_request(client_email: "nope").valid?
    assert_equal "jo@example.com", build_request(client_email: " JO@Example.com ").client_email
  end

  test "rejects a due date in the past" do
    request = build_request(due_on: Date.yesterday)
    assert_not request.valid?
    assert_includes request.errors[:due_on], "can't be in the past"
  end

  test "an existing past due date doesn't block other edits" do
    request = document_requests(:rental)
    request.update_column(:due_on, Date.yesterday)
    assert request.update(title: "Renamed")
  end

  test "progress counts received items" do
    request = document_requests(:rental)
    assert_equal 1, request.received_count
    assert_equal 2, request.items_count
    assert_equal 50, request.progress_percent
    assert_not request.complete?
  end

  test "complete when every item is received" do
    assert document_requests(:visa).complete?
  end

  test "overdue when past due and not complete" do
    request = document_requests(:rental)
    request.due_on = Date.yesterday
    assert request.overdue?

    request.checklist_items.each { it.status = "received" }
    assert_not request.overdue?
  end

  test "pending and complete scopes" do
    requests = users(:one).document_requests
    assert_equal [ document_requests(:rental) ], requests.pending.to_a
    assert_equal [ document_requests(:visa) ], requests.complete.to_a
  end
end
