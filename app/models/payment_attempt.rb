class PaymentAttempt < ApplicationRecord
  belongs_to :booking

  enum :status, { succeeded: "succeeded", failed: "failed" }

  before_validation on: :create do
    self.amount_cents ||= booking&.amount_cents
  end

  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :idempotency_key, presence: true, uniqueness: true
  validates :failure_reason, presence: true, if: :failed?
  validates :booking_id, uniqueness: { conditions: -> { succeeded } }, if: :succeeded?
end
