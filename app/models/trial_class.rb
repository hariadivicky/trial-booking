class TrialClass < ApplicationRecord
  belongs_to :class_subject

  validates :title, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
end
