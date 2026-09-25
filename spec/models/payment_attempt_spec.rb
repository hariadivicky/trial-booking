require "rails_helper"

RSpec.describe PaymentAttempt do
  it "copies the booking amount" do
    booking = create(:booking, amount_cents: 4200)

    expect(create(:payment_attempt, booking: booking).amount_cents).to eq(4200)
  end

  it "requires a booking" do
    attempt = build(:payment_attempt, booking: nil)

    expect(attempt).not_to be_valid
    expect(attempt.errors[:booking]).to include("must exist")
  end

  it "requires an idempotency key" do
    attempt = build(:payment_attempt, idempotency_key: "")

    expect(attempt).not_to be_valid
    expect(attempt.errors[:idempotency_key]).to include("can't be blank")
  end

  it "rejects a reused idempotency key" do
    existing = create(:payment_attempt)
    attempt = build(:payment_attempt, idempotency_key: existing.idempotency_key)

    expect(attempt).not_to be_valid
    expect(attempt.errors[:idempotency_key]).to include("has already been taken")
  end

  it "requires a failure reason when failed" do
    attempt = build(:payment_attempt, status: :failed)

    expect(attempt).not_to be_valid
    expect(attempt.errors[:failure_reason]).to include("can't be blank")
  end

  it "allows retrying a booking after failed attempts" do
    failed = create(:payment_attempt, status: :failed, failure_reason: "card_declined")
    create(:payment_attempt, booking: failed.booking, status: :failed, failure_reason: "card_declined")
    attempt = build(:payment_attempt, booking: failed.booking)

    expect(attempt).to be_valid
  end

  it "rejects a second successful attempt for the same booking" do
    existing = create(:payment_attempt)
    attempt = build(:payment_attempt, booking: existing.booking)

    expect(attempt).not_to be_valid
    expect(attempt.errors[:booking_id]).to include("has already been taken")
  end

  it "is rejected by the database as a second successful attempt" do
    existing = create(:payment_attempt)
    attempt = existing.dup.tap { |a| a.idempotency_key = "another-key" }

    expect { attempt.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "is rejected by the database with a reused idempotency key" do
    existing = create(:payment_attempt, status: :failed, failure_reason: "card_declined")

    expect { existing.dup.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "is rejected by the database with an unknown status" do
    attempt = create(:payment_attempt)

    expect { PaymentAttempt.where(id: attempt.id).update_all("status = 'bogus'") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "is rejected by the database with a negative amount" do
    attempt = create(:payment_attempt)

    expect { attempt.update_column(:amount_cents, -1) }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
