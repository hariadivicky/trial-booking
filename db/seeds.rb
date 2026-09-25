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
