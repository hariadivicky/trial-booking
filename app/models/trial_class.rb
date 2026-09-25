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

  def roster
    bookings.eager_load(student: :parent).order("students.name")
  end

  # Pushes the seats left to every page showing this class.
  def broadcast_seats_later
    broadcast_replace_later_to self, partial: "trial_classes/trial_class"
    broadcast_replace_later_to self, target: [ self, :seats ], partial: "trial_classes/seats"
    broadcast_replace_later_to self, target: [ self, :availability ], partial: "checkouts/availability"
    broadcast_replace_later_to self, :roster, target: [ self, :roster ], partial: "rosters/roster"
  end
end
