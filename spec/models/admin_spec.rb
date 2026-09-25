require "rails_helper"

RSpec.describe Admin do
  it "requires a name" do
    admin = build(:admin, name: "")

    expect(admin).not_to be_valid
    expect(admin.errors[:name]).to include("can't be blank")
  end

  it "requires an email" do
    admin = build(:admin, email: "")

    expect(admin).not_to be_valid
    expect(admin.errors[:email]).to include("can't be blank")
  end

  it "normalizes email" do
    expect(build(:admin, email: " Ops@Example.COM ").email).to eq("ops@example.com")
  end

  it "requires a unique email regardless of case" do
    create(:admin, email: "ops@example.com")
    admin = build(:admin, email: "OPS@example.com")

    expect(admin).not_to be_valid
    expect(admin.errors[:email]).to include("has already been taken")
  end
end
