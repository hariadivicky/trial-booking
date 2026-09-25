# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_25_124956) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "trial_class_id", null: false
    t.string "status", default: "pending", null: false
    t.string "payment_status", default: "pending", null: false
    t.integer "amount_cents", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id", "trial_class_id"], name: "index_bookings_on_student_and_class_live", unique: true, where: "((status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying])::text[]))"
    t.index ["student_id"], name: "index_bookings_on_student_id"
    t.index ["trial_class_id"], name: "index_bookings_on_trial_class_id"
    t.check_constraint "amount_cents >= 0", name: "bookings_amount_cents_non_negative"
    t.check_constraint "payment_status::text = ANY (ARRAY['pending'::character varying, 'paid'::character varying, 'failed'::character varying]::text[])", name: "bookings_payment_status_valid"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'expired'::character varying, 'confirmed'::character varying, 'canceled'::character varying]::text[])", name: "bookings_status_valid"
  end

  create_table "class_subjects", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_class_subjects_on_name", unique: true
  end

  create_table "parents", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_parents_on_email", unique: true
  end

  create_table "students", force: :cascade do |t|
    t.bigint "parent_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_students_on_parent_id"
  end

  create_table "trial_classes", force: :cascade do |t|
    t.bigint "class_subject_id", null: false
    t.string "title", null: false
    t.integer "capacity", default: 4, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "price_cents", null: false
    t.index ["class_subject_id"], name: "index_trial_classes_on_class_subject_id"
    t.check_constraint "capacity > 0", name: "trial_classes_capacity_positive"
    t.check_constraint "price_cents >= 0", name: "trial_classes_price_cents_non_negative"
  end

  add_foreign_key "bookings", "students"
  add_foreign_key "bookings", "trial_classes"
  add_foreign_key "students", "parents"
  add_foreign_key "trial_classes", "class_subjects"
end
