class Booking < ApplicationRecord
  HOLD_DURATION = 15.minutes

  belongs_to :student
  belongs_to :trial_class
  has_many :payment_attempts, dependent: :restrict_with_error

  enum :status, { pending: "pending", expired: "expired", confirmed: "confirmed", canceled: "canceled" }
  enum :payment_status, { pending: "pending", paid: "paid", failed: "failed" }, prefix: :payment

  # Snapshot the price paid and start the seat hold.
  before_validation on: :create do
    self.amount_cents ||= trial_class&.price_cents
    self.expires_at ||= HOLD_DURATION.from_now
  end

  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :student_id, uniqueness: { scope: :trial_class_id, conditions: -> { where(status: %i[pending confirmed]) } },
    if: -> { pending? || confirmed? }
end
