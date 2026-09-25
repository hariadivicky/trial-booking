require "rails_helper"

RSpec.describe ExpireBookingJob do
  it "expires the booking's hold once it has passed" do
    booking = create(:booking, expires_at: 1.second.ago)

    described_class.perform_now(booking)

    expect(booking.reload).to be_expired
  end
end
