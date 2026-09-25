# Fake card processor: only the test card with a current or future MM/YY expiry and a 3-digit CVV is charged.
class MockPaymentGateway
  TEST_CARD = "4242424242424242"
  EXPIRY_FORMAT = %r{\A(0[1-9]|1[0-2])/(\d{2})\z}
  CVV_FORMAT = /\A\d{3}\z/

  Result = Data.define(:failure_reason) do
    def success? = failure_reason.nil?
  end

  def charge(card_number:, card_expiry:, card_cvv:)
    Result.new(failure_reason: failure_reason(card_number, card_expiry, card_cvv))
  end

  private
    def failure_reason(card_number, card_expiry, card_cvv)
      if card_number != TEST_CARD
        "card_declined"
      elsif !valid_expiry?(card_expiry)
        "invalid_expiry"
      elsif !CVV_FORMAT.match?(card_cvv)
        "invalid_cvv"
      end
    end

    # A card stays valid through the last day of its expiry month.
    def valid_expiry?(card_expiry)
      month, year = EXPIRY_FORMAT.match(card_expiry)&.captures
      month.present? && Date.new(2000 + year.to_i, month.to_i).end_of_month >= Date.current
    end
end
