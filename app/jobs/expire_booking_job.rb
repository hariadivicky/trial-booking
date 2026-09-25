class ExpireBookingJob < ApplicationJob
  def perform(booking)
    booking.expire!
  end
end
