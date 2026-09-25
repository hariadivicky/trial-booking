require "rails_helper"

RSpec.describe "Payment hold", type: :system do
  before { driven_by :selenium, using: :headless_chrome }

  it "sends the parent back to checkout the moment the hold runs out" do
    visit root_path
    booking = create(:booking, expires_at: 3.seconds.from_now)

    visit payment_path(booking)
    expect(page).to have_current_path(payment_path(booking))

    expect(page).to have_current_path(checkout_path(booking.trial_class), wait: 6)
    expect(page).to have_text(Payment::HOLD_EXPIRED_MESSAGE)
  end
end
