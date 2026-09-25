# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Parent.find_or_create_by!(email: "parent@example.com") { |parent| parent.name = "Jane Doe" }
Admin.find_or_create_by!(email: "admin@example.com") { |admin| admin.name = "Admin User" }

{ "Math" => [ "Fractions Fun", "Shapes and Angles" ], "Science" => [ "Intro to Physics", "Plants and Seeds" ] }.each do |subject_name, titles|
  class_subject = ClassSubject.find_or_create_by!(name: subject_name)
  titles.each do |title|
    class_subject.trial_classes.find_or_create_by!(title:) { |trial_class| trial_class.price_cents = 2500 }
  end
end

# Three paid students leave Plants and Seeds with one seat, ready for the last-seat race.
plants_and_seeds = TrialClass.find_by!(title: "Plants and Seeds")
{ "mei@example.com" => [ "Mei Tan", "Ethan Tan" ], "raj@example.com" => [ "Raj Kumar", "Priya Kumar" ], "sarah@example.com" => [ "Sarah Lim", "Chloe Lim" ] }.each do |email, (parent_name, child_name)|
  student = Parent.find_or_create_by!(email:) { |parent| parent.name = parent_name }.students.find_or_create_by!(name: child_name)
  booking = plants_and_seeds.bookings.find_or_create_by!(student:) { |booking| booking.assign_attributes(status: :confirmed, payment_status: :paid) }
  booking.payment_attempts.find_or_create_by!(idempotency_key: "seed-booking-#{booking.id}") { |attempt| attempt.status = :succeeded }
end
