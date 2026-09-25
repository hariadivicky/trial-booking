require "rails_helper"

RSpec.describe "Checkouts", type: :request do
  describe "GET /checkout/:trial_class_id" do
    it "renders the checkout page" do
      trial_class = create(:trial_class)

      get checkout_path(trial_class)

      expect(response).to have_http_status(:ok)
      assert_select "h1", "Checkout"
    end
  end
end
