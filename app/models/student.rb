class Student < ApplicationRecord
  belongs_to :parent
  has_many :bookings, dependent: :restrict_with_error

  validates :name, presence: true
end
