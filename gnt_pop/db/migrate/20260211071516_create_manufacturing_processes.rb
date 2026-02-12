class CreateManufacturingProcesses < ActiveRecord::Migration[8.1]
  def change
    create_table :manufacturing_processes do |t|
      t.string :process_code, null: false
      t.string :process_name, null: false
      t.integer :process_order, null: false
      t.decimal :std_cycle_time, precision: 10, scale: 2
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :manufacturing_processes, :process_code, unique: true
  end
end
