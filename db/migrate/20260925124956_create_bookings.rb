class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :student, null: false, foreign_key: true
      t.references :trial_class, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :payment_status, null: false, default: "pending"
      t.integer :amount_cents, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
    # One live (pending or confirmed) booking per student per class; expired/canceled rows don't block a rebook.
    add_index :bookings, [ :student_id, :trial_class_id ], unique: true,
      where: "status IN ('pending', 'confirmed')", name: "index_bookings_on_student_and_class_live"
    add_check_constraint :bookings, "status IN ('pending', 'expired', 'confirmed', 'canceled')", name: "bookings_status_valid"
    add_check_constraint :bookings, "payment_status IN ('pending', 'paid', 'failed')", name: "bookings_payment_status_valid"
    add_check_constraint :bookings, "amount_cents >= 0", name: "bookings_amount_cents_non_negative"
  end
end
