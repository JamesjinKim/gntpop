class CreateEquipments < ActiveRecord::Migration[8.1]
  def change
    create_table :equipments do |t|
      t.string :equipment_code, null: false
      t.string :equipment_name, null: false
      t.references :manufacturing_process, null: false, foreign_key: true
      t.string :location
      t.integer :status, default: 0
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :equipments, :equipment_code, unique: true
  end
end
