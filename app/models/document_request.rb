class DocumentRequest < ApplicationRecord
  belongs_to :user
  has_many :checklist_items, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :document_request

  accepts_nested_attributes_for :checklist_items, allow_destroy: true, reject_if: ->(attributes) { attributes["name"].blank? }

  normalizes :client_email, with: ->(e) { e.strip.downcase }
  normalizes :title, :client_name, with: ->(value) { value.squish }

  validates :title, presence: true, length: { maximum: 120 }
  validates :client_name, presence: true, length: { maximum: 100 }
  validates :client_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, length: { maximum: 2_000 }
  validate :due_on_not_in_the_past, if: -> { due_on.present? && will_save_change_to_due_on? }
  validate :has_at_least_one_checklist_item

  before_validation :number_checklist_items

  # A request is pending while any item is missing and complete once every item is received.
  scope :pending, -> { where(id: ChecklistItem.pending.select(:document_request_id)) }
  scope :complete, -> { where.not(id: ChecklistItem.pending.select(:document_request_id)) }
  scope :recent_first, -> { order(created_at: :desc) }

  def complete?
    checklist_items.none?(&:pending?)
  end

  def received_count
    checklist_items.count(&:received?)
  end

  def items_count
    checklist_items.size
  end

  def progress_percent
    return 0 if items_count.zero?

    (received_count * 100.0 / items_count).round
  end

  def overdue?
    due_on.present? && due_on.past? && !complete?
  end

  private
    def remaining_items
      checklist_items.reject(&:marked_for_destruction?)
    end

    def number_checklist_items
      remaining_items.each.with_index(1) { |item, index| item.position = index }
    end

    def has_at_least_one_checklist_item
      errors.add(:base, "Add at least one document to the checklist") if remaining_items.empty?
    end

    def due_on_not_in_the_past
      errors.add(:due_on, "can't be in the past") if due_on.past?
    end
end
