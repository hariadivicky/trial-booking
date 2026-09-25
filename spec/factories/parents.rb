FactoryBot.define do
  factory :parent do
    name { "Jane Doe" }
    sequence(:email) { |n| "parent#{n}@example.com" }
  end
end
