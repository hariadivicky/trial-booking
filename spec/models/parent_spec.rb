require "rails_helper"

RSpec.describe Parent do
  it "requires a name" do
    parent = build(:parent, name: "")

    expect(parent).not_to be_valid
    expect(parent.errors[:name]).to include("can't be blank")
  end

  it "requires an email" do
    parent = build(:parent, email: "")

    expect(parent).not_to be_valid
    expect(parent.errors[:email]).to include("can't be blank")
  end

  it "normalizes email" do
    expect(build(:parent, email: " Jane@Example.COM ").email).to eq("jane@example.com")
  end

  it "requires a unique email regardless of case" do
    create(:parent, email: "jane@example.com")
    parent = build(:parent, email: "JANE@example.com")

    expect(parent).not_to be_valid
    expect(parent.errors[:email]).to include("has already been taken")
  end

  it "requires an email not used by an admin" do
    create(:admin, email: "jane@example.com")
    parent = build(:parent, email: "Jane@Example.com")

    expect(parent).not_to be_valid
    expect(parent.errors[:email]).to include("has already been taken")
  end

  it "has many students" do
    student = create(:student)

    expect(student.parent.students).to include(student)
  end

  it "cannot be destroyed while it has students" do
    parent = create(:student).parent

    expect(parent.destroy).to be_falsey
    expect(Parent.exists?(parent.id)).to be true
  end
end
