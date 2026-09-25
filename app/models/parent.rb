class Parent < ApplicationRecord
  has_many :students, dependent: :restrict_with_error

  # Downcased so the unique index also catches case variants.
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
