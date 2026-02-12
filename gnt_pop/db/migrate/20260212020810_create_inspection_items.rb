class CreateInspectionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inspection_items do |t|
      t.references :inspection_result, null: false, foreign_key: true
      t.string :item_name, null: false
      t.string :spec_value
      t.decimal :measured_value, precision: 15, scale: 5
      t.string :unit
      t.integer :judgment, default: 0

      t.timestamps
    end
  end
end
