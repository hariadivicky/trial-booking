require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "renders the navbar for a signed-out visitor" do
      get root_path

      expect(response).to have_http_status(:ok)
      assert_select "nav a[href=?]", sign_in_path, text: "Sign in"
    end
  end
end
