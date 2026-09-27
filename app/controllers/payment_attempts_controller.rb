class PaymentAttemptsController < ApplicationController
  before_action :require_admin

  # Every attempt, or a single booking's payment log when nested under it.
  def index
    @booking = Booking.find(params[:booking_id]) if params[:booking_id]
    @payment_attempts = (@booking&.payment_attempts || PaymentAttempt).log
  end
end
