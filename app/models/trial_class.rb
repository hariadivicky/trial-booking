class TrialClass < ApplicationRecord
  belongs_to :class_subject
  has_many :bookings, dependent: :restrict_with_error
  has_many :seat_holding_bookings, -> { holding_seat }, class_name: "Booking"

  validates :title, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def seats_left
    capacity - seat_holding_bookings.size
  end

  def fully_booked?
    seats_left <= 0
  end
end
