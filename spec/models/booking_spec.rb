require "rails_helper"

RSpec.describe Booking do
  it "defaults to pending status and pending payment" do
    booking = Booking.new

    expect(booking).to be_pending
    expect(booking).to be_payment_pending
  end

  it "copies the trial class price into the amount" do
    trial_class = create(:trial_class, price_cents: 4200)

    expect(create(:booking, trial_class: trial_class).amount_cents).to eq(4200)
  end

  it "holds the seat for the hold duration" do
    booking = create(:booking)

    expect(booking.expires_at).to be_within(5.seconds).of(Booking::HOLD_DURATION.from_now)
  end

  it "requires a student" do
    booking = build(:booking, student: nil)

    expect(booking).not_to be_valid
    expect(booking.errors[:student]).to include("must exist")
  end

  it "requires a trial class" do
    booking = build(:booking, trial_class: nil)

    expect(booking).not_to be_valid
    expect(booking.errors[:trial_class]).to include("must exist")
  end

  it "requires a non-negative amount" do
    booking = build(:booking, amount_cents: -1)

    expect(booking).not_to be_valid
    expect(booking.errors[:amount_cents]).to include("must be greater than or equal to 0")
  end

  it "rejects a second pending or confirmed booking for the same student and class" do
    existing = create(:booking, status: :confirmed)
    booking = build(:booking, student: existing.student, trial_class: existing.trial_class)

    expect(booking).not_to be_valid
    expect(booking.errors[:student_id]).to include("has already been taken")
  end

  it "allows rebooking once the earlier booking expired or was canceled" do
    expired = create(:booking, status: :expired)
    create(:booking, student: expired.student, trial_class: expired.trial_class, status: :canceled)
    booking = build(:booking, student: expired.student, trial_class: expired.trial_class)

    expect(booking).to be_valid
  end

  it "cannot be destroyed while it has payment attempts" do
    booking = create(:payment_attempt).booking

    expect(booking.destroy).to be_falsey
    expect(Booking.exists?(booking.id)).to be true
  end

  it "is rejected by the database as a duplicate pending or confirmed booking" do
    existing = create(:booking)

    expect { existing.dup.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "is rejected by the database with an unknown status" do
    booking = create(:booking)

    expect { Booking.where(id: booking.id).update_all("status = 'bogus'") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "is rejected by the database with an unknown payment status" do
    booking = create(:booking)

    expect { Booking.where(id: booking.id).update_all("payment_status = 'bogus'") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "is rejected by the database with a negative amount" do
    booking = create(:booking)

    expect { booking.update_column(:amount_cents, -1) }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
