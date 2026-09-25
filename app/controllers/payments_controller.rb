class PaymentsController < ApplicationController
  def show
    @booking = Booking.find(params[:booking_id])
  end
end
