require "rails_helper"

RSpec.describe "Payments", type: :request do
  describe "GET /pay/:booking_id" do
    it "renders the payment page" do
      booking = create(:booking)

      get payment_path(booking)

      expect(response).to have_http_status(:ok)
      assert_select "h1", "Payment"
    end
  end
end
