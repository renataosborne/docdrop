require "test_helper"

class ChecklistItemTest < ActiveSupport::TestCase
  test "new items are pending" do
    assert ChecklistItem.new.pending?
  end

  test "records when an item is received and clears it when marked missing" do
    item = checklist_items(:rental_address)

    item.update!(status: "received")
    assert_not_nil item.received_at

    item.update!(status: "pending")
    assert_nil item.received_at
  end

  test "rejects unknown statuses" do
    item = checklist_items(:rental_address)
    item.status = "lost"
    assert_not item.valid?
  end

  test "requires a name" do
    item = checklist_items(:rental_address)
    item.name = " "
    assert_not item.valid?
  end
end
