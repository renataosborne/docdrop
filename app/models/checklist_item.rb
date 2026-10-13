class ChecklistItem < ApplicationRecord
  belongs_to :document_request, touch: true

  enum :status, { pending: "pending", received: "received" }, default: :pending, validate: true

  normalizes :name, with: ->(n) { n.squish }

  validates :name, presence: true, length: { maximum: 120 }

  before_save :track_received_at, if: :will_save_change_to_status?

  private
    def track_received_at
      self.received_at = received? ? Time.current : nil
    end
end
