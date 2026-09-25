class CreateTrialClasses < ActiveRecord::Migration[8.1]
  def change
    create_table :trial_classes do |t|
      t.references :class_subject, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :capacity, null: false, default: 4

      t.timestamps
    end
    add_check_constraint :trial_classes, "capacity > 0", name: "trial_classes_capacity_positive"
  end
end
