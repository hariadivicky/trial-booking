class Parent < ApplicationRecord
  has_many :students, dependent: :restrict_with_error

  # Downcased so the unique index also catches case variants.
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validate :email_not_taken_by_admin

  private
    # Sign in looks accounts up by email, so it must be unique across parents and admins.
    def email_not_taken_by_admin
      errors.add(:email, :taken) if Admin.exists?(email:)
    end
end
