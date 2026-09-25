require "rails_helper"

RSpec.describe TrialClass do
  it "defaults capacity to 4" do
    expect(TrialClass.new.capacity).to eq(4)
  end

  it "requires a title" do
    trial_class = build(:trial_class, title: "")

    expect(trial_class).not_to be_valid
    expect(trial_class.errors[:title]).to include("can't be blank")
  end

  it "requires a class subject" do
    trial_class = build(:trial_class, class_subject: nil)

    expect(trial_class).not_to be_valid
    expect(trial_class.errors[:class_subject]).to include("must exist")
  end

  it "requires a positive capacity" do
    trial_class = build(:trial_class, capacity: 0)

    expect(trial_class).not_to be_valid
    expect(trial_class.errors[:capacity]).to include("must be greater than 0")
  end

  it "is rejected by the database with a non-positive capacity" do
    trial_class = create(:trial_class)

    expect { trial_class.update_column(:capacity, 0) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "requires a non-negative price" do
    trial_class = build(:trial_class, price_cents: -1)

    expect(trial_class).not_to be_valid
    expect(trial_class.errors[:price_cents]).to include("must be greater than or equal to 0")
  end

  it "is rejected by the database with a negative price" do
    trial_class = create(:trial_class)

    expect { trial_class.update_column(:price_cents, -1) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "cannot be destroyed while it has bookings" do
    trial_class = create(:booking).trial_class

    expect(trial_class.destroy).to be_falsey
    expect(TrialClass.exists?(trial_class.id)).to be true
  end
end
