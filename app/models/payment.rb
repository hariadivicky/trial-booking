# Pays for a held seat and confirms the booking, under the same class row lock that seat holds take.
class Payment
  include ActiveModel::Model

  FAILURE_MESSAGES = {
    "card_declined" => "Your card was declined.",
    "invalid_expiry" => "Your card's expiry date is invalid or has passed.",
    "invalid_cvv" => "Your CVV must be 3 digits."
  }.freeze
  HOLD_EXPIRED_MESSAGE = "Your seat hold has expired. Please book again."

  attr_accessor :booking, :card_number, :card_expiry, :card_cvv, :idempotency_key

  validates :idempotency_key, presence: true

  def save
    return false if invalid?

    booking.trial_class.with_lock do
      booking.reload
      pay unless booking.confirmed?
    end
    errors.empty?
  end

  private
    def pay
      return expire_hold if booking.lapsed? || !booking.pending?

      # A resubmitted form reuses its earlier attempt instead of charging again.
      attempt = booking.payment_attempts.find_by(idempotency_key:) || charge
      if attempt.succeeded?
        booking.update!(status: :confirmed, payment_status: :paid)
      else
        booking.payment_failed!
        errors.add(:base, FAILURE_MESSAGES.fetch(attempt.failure_reason))
      end
    end

    def charge
      result = MockPaymentGateway.new.charge(card_number:, card_expiry:, card_cvv:)
      booking.payment_attempts.create!(idempotency_key:, status: result.success? ? :succeeded : :failed, failure_reason: result.failure_reason)
    end

    def expire_hold
      booking.expired! if booking.lapsed?
      errors.add(:base, HOLD_EXPIRED_MESSAGE)
    end
end
