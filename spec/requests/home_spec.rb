require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "renders the navbar for a signed-out visitor" do
      get root_path

      expect(response).to have_http_status(:ok)
      assert_select "nav a[href=?]", sign_in_path, text: "Sign in"
    end

    it "lists trial classes grouped by subject" do
      math = create(:class_subject, name: "Math")
      science = create(:class_subject, name: "Science")
      create(:trial_class, class_subject: science, title: "Class B")
      create(:trial_class, class_subject: math, title: "Class C")
      create(:trial_class, class_subject: math, title: "Class A")

      get root_path

      sections = css_select("main section").map { |section| [ section.at("h2").text, section.css("li").map { _1.text.squish } ] }
      expect(sections).to eq([
        [ "Math", [ "Class A · 4 seats left", "Class C · 4 seats left" ] ],
        [ "Science", [ "Class B · 4 seats left" ] ]
      ])
    end

    it "shows seats left and drops the checkout link once a class is fully booked" do
      open_class = create(:trial_class, title: "Class A")
      full_class = create(:trial_class, title: "Class B", capacity: 1)
      create(:booking, trial_class: open_class, status: :confirmed)
      create(:booking, trial_class: full_class, status: :confirmed)

      get root_path

      expect(css_select("main li").map { _1.text.squish }).to contain_exactly("Class A · 3 seats left", "Class B · Fully booked")
      assert_select "main a[href=?]", checkout_path(open_class)
      assert_select "main a[href=?]", checkout_path(full_class), count: 0
    end

    it "links each trial class to its checkout" do
      trial_class = create(:trial_class, title: "Class A")

      get root_path

      assert_select "main li a[href=?]", checkout_path(trial_class), text: "Class A"
    end

    it "links each class to its roster instead of checkout for an admin, even when fully booked" do
      admin = create(:admin)
      post sign_in_otp_path, params: { email: admin.email }
      post sign_in_path, params: { otp: SessionsController::FAKE_OTP }
      open_class = create(:trial_class, title: "Class A")
      full_class = create(:trial_class, title: "Class B", capacity: 1)
      create(:booking, trial_class: full_class, status: :confirmed)

      get root_path

      expect(css_select("main li").map { _1.text.squish }).to contain_exactly("Class A · 4 seats left", "Class B · Fully booked")
      assert_select "main li a[href=?]", roster_path(open_class), text: "Class A"
      assert_select "main li a[href=?]", roster_path(full_class), text: "Class B"
      assert_select "main a[href^='/checkout']", count: 0
    end
  end
end
