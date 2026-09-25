class PaymentsController < ApplicationController
  before_action :set_booking

  def show
    @payment = Payment.new(booking: @booking)
  end

  def create
    @payment = Payment.new(payment_params.merge(booking: @booking))

    if @payment.save
      redirect_to booking_path(@booking)
    elsif @booking.expired?
      redirect_to checkout_path(@booking.trial_class), alert: @payment.errors.full_messages.to_sentence
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def set_booking
      @booking = Booking.find(params[:booking_id])
    end

    def payment_params
      params.expect(payment: %i[card_number card_expiry card_cvv idempotency_key])
    end
end
