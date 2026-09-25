require "rails_helper"

RSpec.describe "Payments", type: :request do
  describe "GET /pay/:booking_id" do
    it "renders the payment page" do
      booking = create(:booking)

      get payment_path(booking)

      expect(response).to have_http_status(:ok)
      assert_select "h1", "Payment"
    end

    it "counts down to the booking's hold expiry" do
      freeze_time
      booking = create(:booking)

      get payment_path(booking)

      assert_select "time[data-controller=countdown][datetime=?]", booking.expires_at.iso8601, text: "15:00"
    end

    it "shows 00:00 once the hold has expired" do
      booking = create(:booking, expires_at: 1.minute.ago)

      get payment_path(booking)

      assert_select "time[data-controller=countdown]", text: "00:00"
    end

    it "renders a card form with test card hints" do
      booking = create(:booking)

      get payment_path(booking)

      assert_select "form[action=?][method=post]", payment_path(booking) do
        assert_select "input[name='payment[card_number]']"
        assert_select "input[name='payment[card_expiry]']"
        assert_select "input[name='payment[card_cvv]']"
        assert_select "input[type=submit][value='Pay now']"
      end
      assert_select "p", "Use 4242424242424242."
      assert_select "p", "Any future month and year."
      assert_select "p", "Any 3 digits."
    end
  end
end
