require "rails_helper"

RSpec.describe "Sign up", type: :system do
  before { driven_by :rack_test }

  def sign_up(name:, email:)
    visit sign_in_path
    click_link "Sign up"
    fill_in "Name", with: name
    fill_in "Email", with: email
    click_button "Sign Up"
  end

  it "signs a new parent up and in" do
    sign_up(name: "Jane Doe", email: "jane@example.com")

    expect(Parent.find_by(email: "jane@example.com").name).to eq("Jane Doe")
    within("nav") do
      expect(page).to have_text("Jane Doe")
      expect(page).to have_button("Sign out")
    end
  end

  it "shows errors and stays signed out when the form is invalid" do
    create(:parent, email: "jane@example.com")

    sign_up(name: "", email: "jane@example.com")

    expect(page).to have_text("Name can't be blank")
    expect(page).to have_text("Email has already been taken")
    within("nav") { expect(page).to have_link("Sign in") }
  end
end
