require "test_helper"

class ChecklistItemTest < ActiveSupport::TestCase
  setup { @item = checklist_items(:rental_address) }

  test "new items are pending" do
    assert ChecklistItem.new.pending?
  end

  test "records when an item is received and clears it when marked missing" do
    @item.update!(status: "received")
    assert_not_nil @item.received_at

    @item.update!(status: "pending")
    assert_nil @item.received_at
  end

  test "rejects unknown statuses" do
    @item.status = "lost"
    assert_not @item.valid?
  end

  test "requires a name" do
    @item.name = " "
    assert_not @item.valid?
  end

  test "submit_files attaches allowed files and marks the item received" do
    assert @item.submit_files([ file_fixture_upload("payslip.pdf", "application/pdf"), file_fixture_upload("photo.png", "image/png") ])

    assert @item.reload.received?
    assert_equal %w[ payslip.pdf photo.png ], @item.files.map { it.filename.to_s }.sort
  end

  test "submit_files rejects a file whose contents aren't an allowed type, even with a .pdf name" do
    assert_not @item.submit_files([ file_fixture_upload("not-really.pdf", "application/pdf") ])

    assert_match "not-really.pdf isn't a PDF, JPG, PNG, HEIC or WebP file", @item.errors[:files].first
    assert_not @item.files.attached?
    assert @item.reload.pending?
  end

  test "submit_files stores nothing if any file in the batch is rejected" do
    assert_not @item.submit_files([ file_fixture_upload("payslip.pdf", "application/pdf"), file_fixture_upload("not-really.pdf", "application/pdf") ])
    assert_not @item.reload.files.attached?
  end

  test "submit_files rejects files over 10 MB" do
    big = Tempfile.new([ "big", ".pdf" ], binmode: true)
    big.write("%PDF-1.4\n")
    big.truncate(ChecklistItem::MAX_FILE_SIZE + 1)
    upload = Rack::Test::UploadedFile.new(big.path, "application/pdf", true, original_filename: "big.pdf")

    assert_not @item.submit_files([ upload ])
    assert_includes @item.errors[:files], "big.pdf is larger than 10 MB."
  ensure
    big&.close!
  end

  test "submit_files limits the number of files per item" do
    uploads = Array.new(ChecklistItem::MAX_FILES + 1) { file_fixture_upload("photo.png", "image/png") }

    assert_not @item.submit_files(uploads)
    assert_includes @item.errors[:files], "You can upload up to 5 files for each document."
  end

  test "submit_files requires at least one file" do
    assert_not @item.submit_files([ "" ])
    assert_includes @item.errors[:files], "Choose a file to upload."
  end
end
