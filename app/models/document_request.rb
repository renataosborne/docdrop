class DocumentRequest < ApplicationRecord
  UPLOAD_LINK_LIFETIME = 30.days

  belongs_to :user
  has_many :checklist_items, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :document_request

  has_secure_token :upload_token

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
  before_create { self.upload_expires_at ||= UPLOAD_LINK_LIFETIME.from_now }

  # A request is pending while any item is missing and complete once every item is received.
  scope :pending, -> { where(id: ChecklistItem.pending.select(:document_request_id)) }
  scope :complete, -> { where.not(id: ChecklistItem.pending.select(:document_request_id)) }
  scope :recent_first, -> { order(created_at: :desc) }

  # Looks up a request for the public upload page. Unknown, disabled and expired links all
  # return nil so the page can't be used to tell which links exist.
  def self.find_by_active_upload_token(token)
    return if token.blank?

    find_by(upload_token: token)&.then { |request| request if request.upload_link_active? }
  end

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

  def upload_link_status
    if !upload_link_enabled? then :disabled
    elsif upload_expires_at.past? then :expired
    else :active
    end
  end

  def upload_link_active?
    upload_link_status == :active
  end

  def enable_upload_link!
    update!(upload_link_enabled: true, upload_expires_at: UPLOAD_LINK_LIFETIME.from_now)
  end

  def disable_upload_link!
    update!(upload_link_enabled: false)
  end

  # Issues a brand-new link; the old one stops working immediately.
  def reset_upload_link!
    transaction do
      regenerate_upload_token
      enable_upload_link!
    end
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
