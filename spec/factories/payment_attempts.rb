FactoryBot.define do
  factory :payment_attempt do
    booking
    status { :succeeded }
    sequence(:idempotency_key) { |n| "key-#{n}" }
  end
end
