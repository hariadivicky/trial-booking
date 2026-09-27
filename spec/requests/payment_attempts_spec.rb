require "rails_helper"

RSpec.describe "Payment attempts", type: :request do
  def sign_in_as(user)
    post sign_in_otp_path, params: { email: user.email }
    post sign_in_path, params: { otp: SessionsController::FAKE_OTP }
  end

  def attempt_rows
    css_select("main tbody tr").map { |row| row.css("td").map { _1.text.squish } }
  end

  let(:booking) do
    create(:booking, amount_cents: 2500, trial_class: create(:trial_class, title: "Intro to Physics"),
      student: create(:student, name: "Timmy Doe", parent: create(:parent, name: "Jane Doe")))
  end

  describe "GET /payment_attempts" do
    context "as an admin" do
      before { sign_in_as create(:admin) }

      it "lists every attempt newest first, with its failure reason" do
        create(:payment_attempt, booking:, status: :failed, failure_reason: "card_declined", created_at: 2.minutes.ago)
        create(:payment_attempt, booking:, created_at: 1.minute.ago)

        get payment_attempts_path

        expect(response).to have_http_status(:ok)
        assert_select "h1", "Payments"
        expect(attempt_rows.map { _1.drop(1) }).to eq([
          [ "Intro to Physics", "Timmy Doe", "Jane Doe", "SGD 25.00", "Succeeded", "" ],
          [ "Intro to Physics", "Timmy Doe", "Jane Doe", "SGD 25.00", "Failed", "Card declined" ]
        ])
      end

      it "links each attempt to its booking's payment log" do
        create(:payment_attempt, booking:)

        get payment_attempts_path

        assert_select "main td a[href=?]", booking_payment_attempts_path(booking), text: "Timmy Doe"
      end

      it "subscribes to new attempts and skips Turbo's cached preview" do
        get payment_attempts_path

        assert_select "turbo-cable-stream-source[signed-stream-name=?]", Turbo::StreamsChannel.signed_stream_name(:payment_attempts)
        assert_select "main tbody#payment_attempts"
        assert_select "head meta[name='turbo-cache-control'][content='no-preview']"
      end

      it "says so when there are no attempts yet" do
        get payment_attempts_path

        assert_select "main tbody tr", "No payments yet."
      end
    end

    it "sends a signed-in parent home" do
      sign_in_as create(:parent)

      get payment_attempts_path

      expect(response).to redirect_to(root_path)
    end

    it "sends a signed-out visitor home" do
      get payment_attempts_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /bookings/:booking_id/payment_attempts" do
    before { sign_in_as create(:admin) }

    it "shows the booking and only its own attempts" do
      booking.update!(payment_status: :failed)
      create(:payment_attempt, booking:, status: :failed, failure_reason: "invalid_expiry")
      create(:payment_attempt, status: :failed, failure_reason: "card_declined")

      get booking_payment_attempts_path(booking)

      expect(response).to have_http_status(:ok)
      assert_select "h1", "Payment log"
      expect(css_select("main dd").map(&:text)).to eq([ "Intro to Physics", "Timmy Doe", "Jane Doe", "Pending", "Failed" ])
      expect(attempt_rows.map(&:last)).to eq([ "Invalid expiry" ])
    end

    it "subscribes to the booking's new attempts and status" do
      get booking_payment_attempts_path(booking)

      assert_select "turbo-cable-stream-source[signed-stream-name=?]", Turbo::StreamsChannel.signed_stream_name([ booking, :payment_attempts ])
      assert_select "turbo-cable-stream-source[signed-stream-name=?]", Turbo::StreamsChannel.signed_stream_name(booking)
      assert_select "turbo-cable-stream-source[signed-stream-name=?]", Turbo::StreamsChannel.signed_stream_name(:payment_attempts), count: 0
    end

    it "sends a parent home" do
      delete sign_out_path
      sign_in_as booking.student.parent

      get booking_payment_attempts_path(booking)

      expect(response).to redirect_to(root_path)
    end
  end
end
