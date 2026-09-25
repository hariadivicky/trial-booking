require "rails_helper"

RSpec.describe "Demo resets", type: :request do
  def sign_in_as(user)
    post sign_in_otp_path, params: { email: user.email }
    post sign_in_path, params: { otp: SessionsController::FAKE_OTP }
  end

  describe "POST /demo_reset" do
    it "reseeds the app and sends the admin, whose account was recreated, to sign in" do
      sign_in_as create(:admin)
      create(:booking)

      post demo_reset_path

      expect(response).to redirect_to(sign_in_path)
      expect(Booking.confirmed.count).to eq(3)
      get root_path
      assert_select "nav a[href=?]", sign_in_path
    end

    it "does not let a parent reset the demo" do
      sign_in_as create(:parent)

      expect { post demo_reset_path }.not_to change(Parent, :count)
      expect(response).to redirect_to(root_path)
    end

    it "does not let a signed-out visitor reset the demo" do
      expect { post demo_reset_path }.not_to change(TrialClass, :count)
      expect(response).to redirect_to(root_path)
    end
  end
end
