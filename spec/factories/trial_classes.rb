FactoryBot.define do
  factory :trial_class do
    class_subject
    title { "Intro to Physics" }
    price_cents { 2500 }
  end
end
