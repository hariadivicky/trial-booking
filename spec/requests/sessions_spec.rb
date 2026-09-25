require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /sign_in" do
    it "links to sign up" do
      get sign_in_path

      expect(response).to have_http_status(:ok)
      assert_select "main a[href=?]", sign_up_path, text: "Sign up"
    end
  end

  describe "DELETE /sign_out" do
    it "redirects home" do
      delete sign_out_path

      expect(response).to redirect_to(root_path)
    end
  end
end
