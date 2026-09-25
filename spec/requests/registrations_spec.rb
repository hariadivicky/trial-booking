require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /sign_up" do
    it "links back to sign in" do
      get sign_up_path

      expect(response).to have_http_status(:ok)
      assert_select "main a[href=?]", sign_in_path, text: "Sign in"
    end
  end
end
