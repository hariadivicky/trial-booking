class CreateClassSubjects < ActiveRecord::Migration[8.1]
  def change
    create_table :class_subjects do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :class_subjects, :name, unique: true
  end
end
