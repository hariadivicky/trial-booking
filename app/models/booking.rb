class Booking < ApplicationRecord
  HOLD_DURATION = 15.minutes

  belongs_to :student
  belongs_to :trial_class
  has_many :payment_attempts, dependent: :restrict_with_error

  enum :status, { pending: "pending", expired: "expired", confirmed: "confirmed", canceled: "canceled" }
  enum :payment_status, { pending: "pending", paid: "paid", failed: "failed" }, prefix: :payment

  # A seat is taken by a confirmed booking or a pending one whose hold hasn't expired.
  scope :holding_seat, -> { confirmed.or(pending.where(expires_at: Time.current..)) }

  # Snapshot the price paid and start the seat hold.
  before_validation on: :create do
    self.amount_cents ||= trial_class&.price_cents
    self.expires_at ||= HOLD_DURATION.from_now
  end

  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :student_id, uniqueness: { scope: :trial_class_id, conditions: -> { where(status: %i[pending confirmed]) }, message: "is already booked in this class" },
    if: -> { pending? || confirmed? }
  validate :seat_available, on: :create

  # Locks the class row so concurrent checkouts can't both take its last seat.
  def self.hold_seat!(trial_class:, student:)
    trial_class.with_lock { create!(trial_class:, student:) }
  end

  private
    # Counts in the database; association #size would cache an empty result on the class.
    def seat_available
      return unless trial_class

      errors.add(:base, "This class is fully booked") if trial_class.seat_holding_bookings.count >= trial_class.capacity
    end
end
