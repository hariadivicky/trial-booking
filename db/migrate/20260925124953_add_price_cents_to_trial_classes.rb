class AddPriceCentsToTrialClasses < ActiveRecord::Migration[8.1]
  def change
    add_column :trial_classes, :price_cents, :integer, null: false
    add_check_constraint :trial_classes, "price_cents >= 0", name: "trial_classes_price_cents_non_negative"
  end
end
