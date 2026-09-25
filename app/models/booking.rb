class Booking < ApplicationRecord
  HOLD_DURATION = 30.seconds

  belongs_to :student
  belongs_to :trial_class
  has_many :payment_attempts, dependent: :restrict_with_error

  enum :status, { pending: "pending", expired: "expired", confirmed: "confirmed", canceled: "canceled" }
  enum :payment_status, { pending: "pending", paid: "paid", failed: "failed" }, prefix: :payment

  scope :held, -> { pending.where(expires_at: Time.current..) }
  # A seat is taken by a confirmed booking or a pending one whose hold hasn't expired.
  scope :holding_seat, -> { confirmed.or(held) }
  # Past its deadline but still pending until the expiry job runs; trust this over the status.
  scope :lapsed, -> { pending.where(expires_at: ...Time.current) }

  # Snapshot the price paid and start the seat hold.
  before_validation on: :create do
    self.amount_cents ||= trial_class&.price_cents
    self.expires_at ||= HOLD_DURATION.from_now
  end

  after_create_commit { ExpireBookingJob.set(wait_until: expires_at).perform_later(self) }
  after_commit { trial_class.broadcast_seats_later }
  after_update_commit { broadcast_replace_later_to self, target: [ self, :status ], partial: "bookings/status" }

  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :student_id, uniqueness: { scope: :trial_class_id, conditions: -> { where(status: %i[pending confirmed]) }, message: "is already booked in this class" },
    if: -> { pending? || confirmed? }
  validate :seat_available, on: :create

  # Locks the class row so concurrent checkouts can't both take its last seat.
  # Expires the student's own lapsed hold first, since the unique index only sees status.
  def self.hold_seat!(trial_class:, student:)
    trial_class.with_lock do
      trial_class.bookings.lapsed.find_by(student:)&.expired!
      create!(trial_class:, student:)
    end
  end

  # Fallback sweep for holds whose expiry job never ran.
  def self.expire_stale!
    lapsed.find_each(&:expire!)
  end

  # Takes the class lock like Payment, so a hold can't expire mid-payment.
  def expire!
    trial_class.with_lock do
      reload
      expired! if lapsed?
    end
  end

  def lapsed?
    pending? && expires_at.past?
  end

  private
    # Counts in the database; association #size would cache an empty result on the class.
    def seat_available
      return unless trial_class

      errors.add(:base, "This class is fully booked") if trial_class.seat_holding_bookings.count >= trial_class.capacity
    end
end
