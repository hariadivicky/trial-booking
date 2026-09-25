class Student < ApplicationRecord
  belongs_to :parent
  has_many :bookings, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, uniqueness: { scope: :parent_id, case_sensitive: false }
end
