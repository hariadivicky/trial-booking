require "rails_helper"

RSpec.describe "Bookings", type: :request do
  describe "GET /bookings/:id" do
    it "shows the class, child, amount and booking status" do
      booking = create(:booking, status: :confirmed, payment_status: :paid,
        trial_class: create(:trial_class, title: "Intro to Physics", price_cents: 2500),
        student: create(:student, name: "Timmy Doe"))

      get booking_path(booking)

      expect(response).to have_http_status(:ok)
      assert_select "h1", "Your booking"
      assert_select "dd", "Intro to Physics"
      assert_select "dd", "Timmy Doe"
      assert_select "dd", "SGD 25.00"
      assert_select "dd", "Confirmed"
      assert_select "dd", "Paid"
    end

    it "shows Expired once the hold lapsed, before the job expires it" do
      booking = create(:booking, expires_at: 1.second.ago)

      get booking_path(booking)

      assert_select "dd", "Expired"
    end
  end
end
