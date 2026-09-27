require "rails_helper"

RSpec.describe "Rosters", type: :request do
  include ActionView::RecordIdentifier

  def sign_in_as(user)
    post sign_in_otp_path, params: { email: user.email }
    post sign_in_path, params: { otp: SessionsController::FAKE_OTP }
  end

  def book(child_name, parent_name, **attributes)
    parent = create(:parent, name: parent_name)
    create(:booking, trial_class:, student: create(:student, parent:, name: child_name), **attributes)
  end

  def roster_rows
    css_select("main section").to_h do |section|
      [ section.at("h2").text, section.css("tbody tr").map { |row| row.css("td").map(&:text) } ]
    end
  end

  let(:trial_class) { create(:trial_class, title: "Intro to Physics") }

  describe "GET /trial_classes/:trial_class_id/roster" do
    context "as an admin" do
      before { sign_in_as create(:admin) }

      it "lists confirmed children apart from live holds, with their parent" do
        confirmed = book("Timmy Doe", "Jane Doe", status: :confirmed, payment_status: :paid)
        held = book("Anna Lee", "Mary Lee")

        get roster_path(trial_class)

        expect(response).to have_http_status(:ok)
        assert_select "h1", "Intro to Physics roster"
        assert_select "main p", "1 of 4 confirmed · 1 seat on hold"
        expect(roster_rows).to eq(
          "Confirmed" => [ [ "Timmy Doe", "Jane Doe", confirmed.student.parent.email ] ],
          "On hold" => [ [ "Anna Lee", "Mary Lee", held.student.parent.email ] ]
        )
      end

      it "links each child to their booking's payment log" do
        confirmed = book("Timmy Doe", "Jane Doe", status: :confirmed, payment_status: :paid)
        held = book("Anna Lee", "Mary Lee")

        get roster_path(trial_class)

        assert_select "main td a[href=?]", booking_payment_attempts_path(confirmed), text: "Timmy Doe"
        assert_select "main td a[href=?]", booking_payment_attempts_path(held), text: "Anna Lee"
      end

      it "subscribes to the class's roster updates" do
        get roster_path(trial_class)

        assert_select "turbo-cable-stream-source[signed-stream-name=?]", Turbo::StreamsChannel.signed_stream_name([ trial_class, :roster ])
        assert_select "main ##{dom_id(trial_class, :roster)} section", 2
      end

      it "skips Turbo's cached preview so a revisit keeps its roster subscription" do
        get roster_path(trial_class)

        assert_select "head meta[name='turbo-cache-control'][content='no-preview']"
      end

      it "keeps a failed payment off the confirmed roster" do
        book("Timmy Doe", "Jane Doe", payment_status: :failed)

        get roster_path(trial_class)

        expect(roster_rows["Confirmed"]).to be_empty
        expect(roster_rows["On hold"].map(&:first)).to eq([ "Timmy Doe" ])
      end

      it "leaves out expired, canceled and lapsed bookings" do
        book("Expired Kid", "Jane Doe", status: :expired)
        book("Canceled Kid", "Mary Lee", status: :canceled)
        book("Lapsed Kid", "John Roe", expires_at: 1.second.ago)

        get roster_path(trial_class)

        expect(roster_rows).to eq("Confirmed" => [], "On hold" => [])
        assert_select "main p", "No confirmed students yet."
        assert_select "main p", "No seats on hold."
      end
    end

    it "sends a signed-in parent home" do
      sign_in_as create(:parent)

      get roster_path(trial_class)

      expect(response).to redirect_to(root_path)
    end

    it "sends a signed-out visitor home" do
      get roster_path(trial_class)

      expect(response).to redirect_to(root_path)
    end
  end
end
