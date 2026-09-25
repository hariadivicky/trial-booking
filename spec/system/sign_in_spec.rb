require "rails_helper"

RSpec.describe "Sign in", type: :system do
  before { driven_by :rack_test }

  def request_otp(email)
    visit sign_in_path
    fill_in "Email", with: email
    click_button "Send OTP"
  end

  it "asks only for an email first" do
    visit sign_in_path

    expect(page).to have_field("Email")
    expect(page).to have_button("Send OTP")
    expect(page).not_to have_field("OTP")
  end

  it "signs a parent in with the OTP" do
    create(:parent, name: "Jane Doe", email: "jane@example.com")

    request_otp("jane@example.com")
    expect(page).to have_text("Use 1234 as the code")
    fill_in "OTP", with: "1234"
    click_button "Sign In"

    within("nav") do
      expect(page).to have_text("Jane Doe")
      expect(page).to have_button("Sign out")
    end
  end

  it "signs an admin in with the OTP" do
    create(:admin, name: "Ada Admin", email: "ada@example.com")

    request_otp("ada@example.com")
    fill_in "OTP", with: "1234"
    click_button "Sign In"

    within("nav") { expect(page).to have_text("Ada Admin") }
  end

  it "rejects a wrong code and lets the user try again" do
    create(:parent, name: "Jane Doe", email: "jane@example.com")

    request_otp("jane@example.com")
    fill_in "OTP", with: "0000"
    click_button "Sign In"

    expect(page).to have_text("Wrong code, try again.")
    expect(page).to have_field("OTP")
    within("nav") { expect(page).to have_link("Sign in") }
  end

  it "rejects an unknown email" do
    request_otp("nobody@example.com")

    expect(page).to have_text("No account found for that email.")
    expect(page).not_to have_field("OTP")
  end

  it "sends the user back to the email step when no OTP was requested" do
    visit sign_in_otp_path

    expect(page).to have_current_path(sign_in_path)
  end

  it "signs the user out" do
    create(:parent, email: "jane@example.com")
    request_otp("jane@example.com")
    fill_in "OTP", with: "1234"
    click_button "Sign In"

    click_button "Sign out"

    within("nav") { expect(page).to have_link("Sign in") }
  end
end
