class ClassSubject < ApplicationRecord
  has_many :trial_classes, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
