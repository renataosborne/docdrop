class ChecklistItem < ApplicationRecord
  ALLOWED_CONTENT_TYPES = {
    "application/pdf" => "PDF", "image/jpeg" => "JPG", "image/png" => "PNG", "image/heic" => "HEIC", "image/webp" => "WebP"
  }.freeze
  MAX_FILE_SIZE = 10.megabytes
  MAX_FILES = 5

  belongs_to :document_request, touch: true
  has_many_attached :files

  enum :status, { pending: "pending", received: "received" }, default: :pending, validate: true

  normalizes :name, with: ->(n) { n.squish }

  validates :name, presence: true, length: { maximum: 120 }

  before_save :track_received_at, if: :will_save_change_to_status?

  # Attaches files uploaded by the client and marks the item received.
  # Every file is checked before anything is stored, so a bad file never lands in storage.
  # Returns false and adds errors if any file is rejected.
  def submit_files(uploads)
    uploads = Array(uploads).compact_blank

    if uploads.empty?
      errors.add(:files, "Choose a file to upload.")
    elsif files.count + uploads.size > MAX_FILES
      errors.add(:files, "You can upload up to #{MAX_FILES} files for each document.")
    end
    uploads.each { |upload| check_upload(upload) }
    return false if errors.any?

    transaction do
      files.attach(uploads)
      update!(status: "received")
    end
  end

  private
    def track_received_at
      self.received_at = received? ? Time.current : nil
    end

    def check_upload(upload)
      if upload.size > MAX_FILE_SIZE
        errors.add(:files, "#{upload.original_filename} is larger than #{MAX_FILE_SIZE / 1.megabyte} MB.")
      end

      # Identify the type from the file's contents (magic bytes), not its name or the browser's claim,
      # so a renamed file can't slip through.
      unless ALLOWED_CONTENT_TYPES.key?(Marcel::MimeType.for(upload.to_io))
        errors.add(:files, "#{upload.original_filename} isn't a #{ALLOWED_CONTENT_TYPES.values.to_sentence(last_word_connector: " or ")} file.")
      end
    ensure
      upload.rewind
    end
end
