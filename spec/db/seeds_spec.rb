require "rails_helper"

RSpec.describe "Seeds" do
  it "fills Plants and Seeds with 3 confirmed, paid students, leaving the last seat" do
    Rails.application.load_seed

    trial_class = TrialClass.find_by!(title: "Plants and Seeds")
    confirmed = trial_class.bookings.confirmed.payment_paid
    expect(confirmed.count).to eq(3)
    expect(confirmed.map { _1.payment_attempts.succeeded.count }).to eq([ 1, 1, 1 ])
    expect(trial_class.seats_left).to eq(1)
  end

  it "can run twice without duplicating records" do
    Rails.application.load_seed

    expect { Rails.application.load_seed }.not_to change { [ Parent, Student, Booking, PaymentAttempt ].map(&:count) }
  end
end
