class Student < ApplicationRecord
  belongs_to :parent

  validates :name, presence: true
end
