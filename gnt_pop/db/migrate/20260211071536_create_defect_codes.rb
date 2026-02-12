class CreateDefectCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :defect_codes do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :defect_codes, :code, unique: true
  end
end
