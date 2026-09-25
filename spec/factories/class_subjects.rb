FactoryBot.define do
  factory :class_subject do
    sequence(:name) { |n| "Subject #{n}" }
  end
end
