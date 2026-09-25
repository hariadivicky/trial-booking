require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "renders the navbar for a signed-out visitor" do
      get root_path

      expect(response).to have_http_status(:ok)
      assert_select "nav a[href=?]", sign_in_path, text: "Sign in"
    end

    it "lists trial classes grouped by subject" do
      math = create(:class_subject, name: "Math")
      science = create(:class_subject, name: "Science")
      create(:trial_class, class_subject: science, title: "Class B")
      create(:trial_class, class_subject: math, title: "Class C")
      create(:trial_class, class_subject: math, title: "Class A")

      get root_path

      sections = css_select("main section").map { |section| [ section.at("h2").text, section.css("li").map(&:text) ] }
      expect(sections).to eq([ [ "Math", [ "Class A", "Class C" ] ], [ "Science", [ "Class B" ] ] ])
    end
  end
end
