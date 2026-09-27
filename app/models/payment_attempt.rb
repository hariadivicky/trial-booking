class PaymentAttempt < ApplicationRecord
  belongs_to :booking

  enum :status, { succeeded: "succeeded", failed: "failed" }

  # Newest first, with the booking details each log row shows.
  scope :log, -> { includes(booking: [ :trial_class, { student: :parent } ]).order(created_at: :desc) }

  before_validation on: :create do
    self.amount_cents ||= booking&.amount_cents
  end

  # Admin-only streams, since each row names the child and parent.
  after_create_commit do
    broadcast_prepend_later_to :payment_attempts, target: "payment_attempts"
    broadcast_prepend_later_to booking, :payment_attempts, target: "payment_attempts"
  end

  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :idempotency_key, presence: true, uniqueness: true
  validates :failure_reason, presence: true, if: :failed?
  validates :booking_id, uniqueness: { conditions: -> { succeeded } }, if: :succeeded?
end
