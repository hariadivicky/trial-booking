require "rails_helper"

RSpec.describe Payment do
  let(:booking) { create(:booking) }
  let(:params) { { booking:, idempotency_key: "key-1", card_number: "4242424242424242", card_expiry: "12/30", card_cvv: "123" } }

  def pay(**attributes)
    Payment.new(params.merge(attributes))
  end

  it "confirms the booking when the card is charged" do
    expect(pay.save).to be(true)
    expect(booking.reload).to have_attributes(status: "confirmed", payment_status: "paid")
    expect(booking.payment_attempts.sole).to have_attributes(status: "succeeded", amount_cents: booking.amount_cents, idempotency_key: "key-1")
  end

  it "keeps the seat held and records why a rejected card failed" do
    payment = pay(card_number: "4000000000000002")

    expect(payment.save).to be(false)
    expect(payment.errors[:base]).to eq([ "Your card was declined." ])
    expect(booking.reload).to have_attributes(status: "pending", payment_status: "failed")
    expect(booking.payment_attempts.sole).to have_attributes(status: "failed", failure_reason: "card_declined")
  end

  it "confirms a retry after a rejected card" do
    pay(card_cvv: "12").save

    expect(pay(idempotency_key: "key-2").save).to be(true)
    expect(booking.reload).to be_confirmed
  end

  it "doesn't charge again for a resubmitted form" do
    pay(card_cvv: "12").save

    payment = pay(card_cvv: "12")
    expect { payment.save }.not_to change(PaymentAttempt, :count)
    expect(payment.errors[:base]).to eq([ "Your CVV must be 3 digits." ])
  end

  it "doesn't charge an already confirmed booking again" do
    pay.save

    expect { expect(pay(idempotency_key: "key-2").save).to be(true) }.not_to change(PaymentAttempt, :count)
  end

  it "requires an idempotency key" do
    payment = pay(idempotency_key: "")

    expect(payment.save).to be(false)
    expect(payment.errors[:idempotency_key]).to include("can't be blank")
    expect(booking.payment_attempts).to be_empty
  end

  it "rejects payment once the hold has expired, without charging" do
    booking.update!(expires_at: 1.minute.ago)
    payment = pay

    expect(payment.save).to be(false)
    expect(payment.errors[:base]).to eq([ "Your seat hold has expired. Please book again." ])
    expect(booking.reload).to be_expired
    expect(booking.payment_attempts).to be_empty
  end

  it "confirms only one booking when an expired hold loses the last seat to another parent" do
    trial_class = create(:trial_class, capacity: 1)
    parent_a = create(:booking, trial_class:)
    travel Booking::HOLD_DURATION + 1.minute
    parent_b = Booking.hold_seat!(trial_class:, student: create(:student, name: "Anna Doe"))

    expect(pay(booking: parent_b, idempotency_key: "key-b").save).to be(true)
    expect(pay(booking: parent_a, idempotency_key: "key-a").save).to be(false)
    expect(trial_class.bookings.confirmed).to eq([ parent_b ])
  end
end
