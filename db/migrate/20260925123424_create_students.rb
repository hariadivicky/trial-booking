class CreateStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :students do |t|
      t.references :parent, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
