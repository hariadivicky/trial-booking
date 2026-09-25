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
        assert_select "input[type=hidden][name='payment[idempotency_key]'][value]"
        assert_select "input[type=submit][value='Pay now']"
      end
      assert_select "p", "Use 4242424242424242."
      assert_select "p", "Any future month and year."
      assert_select "p", "Any 3 digits."
    end
  end

  describe "POST /pay/:booking_id" do
    let(:booking) { create(:booking) }
    let(:card) { { card_number: "4242424242424242", card_expiry: "12/30", card_cvv: "123", idempotency_key: "key-1" } }

    it "confirms the booking and shows its status" do
      post payment_path(booking), params: { payment: card }

      expect(response).to redirect_to(booking_path(booking))
      follow_redirect!
      assert_select "dd", "Confirmed"
    end

    it "shows why a rejected card failed with a fresh attempt key" do
      post payment_path(booking), params: { payment: card.merge(card_cvv: "12") }

      expect(response).to have_http_status(:unprocessable_entity)
      assert_select "li", "Your CVV must be 3 digits."
      assert_select "input[type=hidden][name='payment[idempotency_key]']:not([value='key-1'])"
    end

    it "sends the parent back to checkout once the hold has expired" do
      booking.update!(expires_at: 1.minute.ago)

      post payment_path(booking), params: { payment: card }

      expect(response).to redirect_to(checkout_path(booking.trial_class))
      expect(flash[:alert]).to eq("Your seat hold has expired. Please book again.")
    end
  end
end
