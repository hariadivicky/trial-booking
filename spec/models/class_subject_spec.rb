require "rails_helper"

RSpec.describe ClassSubject do
  it "requires a name" do
    class_subject = build(:class_subject, name: "")

    expect(class_subject).not_to be_valid
    expect(class_subject.errors[:name]).to include("can't be blank")
  end

  it "requires a unique name" do
    existing = create(:class_subject)
    class_subject = build(:class_subject, name: existing.name)

    expect(class_subject).not_to be_valid
    expect(class_subject.errors[:name]).to include("has already been taken")
  end

  it "has many trial classes" do
    trial_class = create(:trial_class)

    expect(trial_class.class_subject.trial_classes).to include(trial_class)
  end

  it "cannot be destroyed while it has trial classes" do
    class_subject = create(:trial_class).class_subject

    expect(class_subject.destroy).to be_falsey
    expect(ClassSubject.exists?(class_subject.id)).to be true
  end
end
