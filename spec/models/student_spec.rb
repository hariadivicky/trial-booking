require "rails_helper"

RSpec.describe Student do
  it "requires a name" do
    student = build(:student, name: "")

    expect(student).not_to be_valid
    expect(student.errors[:name]).to include("can't be blank")
  end

  it "requires a parent" do
    student = build(:student, parent: nil)

    expect(student).not_to be_valid
    expect(student.errors[:parent]).to include("must exist")
  end
end
