require "rails_helper"

RSpec.describe MockPaymentGateway do
  let(:gateway) { described_class.new }
  let(:card) { { card_number: "4242424242424242", card_expiry: "12/30", card_cvv: "123" } }

  before { travel_to Date.new(2026, 9, 15) }

  it "charges the test card" do
    result = gateway.charge(**card)

    expect(result).to be_success
    expect(result.failure_reason).to be_nil
  end

  it "accepts an expiry in the current month" do
    expect(gateway.charge(**card, card_expiry: "09/26")).to be_success
  end

  it "declines any other card number" do
    [ "4000000000000002", "4242 4242 4242 4242", "", nil ].each do |number|
      result = gateway.charge(**card, card_number: number)

      expect(result).not_to be_success
      expect(result.failure_reason).to eq("card_declined")
    end
  end

  it "rejects an expiry in the past" do
    expect(gateway.charge(**card, card_expiry: "08/26").failure_reason).to eq("invalid_expiry")
  end

  it "rejects an expiry not in MM/YY format" do
    [ "9/26", "00/26", "13/26", "09/2026", "0926", "09/26\n", "", nil ].each do |expiry|
      expect(gateway.charge(**card, card_expiry: expiry).failure_reason).to eq("invalid_expiry")
    end
  end

  it "rejects a CVV that is not 3 digits" do
    [ "12", "1234", "12a", "123\n", "", nil ].each do |cvv|
      expect(gateway.charge(**card, card_cvv: cvv).failure_reason).to eq("invalid_cvv")
    end
  end
end
