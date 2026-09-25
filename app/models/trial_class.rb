class TrialClass < ApplicationRecord
  belongs_to :class_subject
  has_many :bookings, dependent: :restrict_with_error

  validates :title, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
