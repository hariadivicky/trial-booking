class CreatePaymentAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_attempts do |t|
      t.references :booking, null: false, foreign_key: true
      t.string :status, null: false
      t.integer :amount_cents, null: false
      t.string :failure_reason
      t.string :idempotency_key, null: false

      t.timestamps
    end
    add_index :payment_attempts, :idempotency_key, unique: true
    # Failed attempts can pile up on retry, but a booking is only ever paid once.
    add_index :payment_attempts, :booking_id, unique: true,
      where: "status = 'succeeded'", name: "index_payment_attempts_on_booking_succeeded"
    add_check_constraint :payment_attempts, "status IN ('succeeded', 'failed')", name: "payment_attempts_status_valid"
    add_check_constraint :payment_attempts, "amount_cents >= 0", name: "payment_attempts_amount_cents_non_negative"
  end
end
