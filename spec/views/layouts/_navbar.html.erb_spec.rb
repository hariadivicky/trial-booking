require "rails_helper"

RSpec.describe "layouts/_navbar", type: :view do
  it "links the logo home" do
    render partial: "layouts/navbar", locals: { user: nil }

    expect(rendered).to have_link("Trial Booking", href: root_path)
  end

  context "when signed out" do
    it "shows a Sign in link" do
      render partial: "layouts/navbar", locals: { user: nil }

      expect(rendered).to have_link("Sign in", href: sign_in_path)
      expect(rendered).not_to have_button("Sign out")
    end
  end

  context "when signed in" do
    it "shows the user's name and a Sign out button" do
      render partial: "layouts/navbar", locals: { user: build(:parent, name: "Jane Doe") }

      expect(rendered).to have_text("Jane Doe")
      expect(rendered).to have_button("Sign out")
      expect(rendered).not_to have_link("Sign in")
    end
  end
end
