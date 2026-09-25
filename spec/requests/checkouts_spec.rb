require "rails_helper"

RSpec.describe "Checkouts", type: :request do
  def sign_in_as(user)
    post sign_in_otp_path, params: { email: user.email }
    post sign_in_path, params: { otp: SessionsController::FAKE_OTP }
  end

  describe "GET /checkout/:trial_class_id" do
    let(:trial_class) { create(:trial_class, title: "Intro to Physics", price_cents: 2500) }

    it "summarises the trial class and its price" do
      get checkout_path(trial_class)

      expect(response).to have_http_status(:ok)
      assert_select "h1", "Checkout"
      assert_select "dd", "Intro to Physics"
      assert_select "dd", "SGD 25.00"
    end

    it "asks a signed-out parent for their name and email" do
      get checkout_path(trial_class)

      assert_select "input[type=text][name=?]", "parent[name]"
      assert_select "input[type=email][name=?]", "parent[email]"
    end

    it "shows a signed-in parent's name instead of asking for it" do
      sign_in_as create(:parent, name: "Jane Doe")

      get checkout_path(trial_class)

      assert_select "main fieldset", text: /Jane Doe/
      assert_select "input[name^=?]", "parent[", count: 0
    end

    it "asks for the child's name and offers a book button" do
      get checkout_path(trial_class)

      assert_select "form[action=?]", checkout_path(trial_class) do
        assert_select "input[type=text][name=?]", "student[name]"
        assert_select "input[type=submit][value=?]", "Book trial class"
      end
    end

    it "returns not found for an unknown class" do
      get checkout_path(trial_class_id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end
end
