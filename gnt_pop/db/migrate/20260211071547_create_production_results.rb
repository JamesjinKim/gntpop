class CreateProductionResults < ActiveRecord::Migration[8.1]
  def change
    create_table :production_results do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :manufacturing_process, null: false, foreign_key: true
      t.references :equipment, foreign_key: { to_table: :equipments }
      t.references :worker, foreign_key: true
      t.string :lot_no, null: false
      t.integer :good_qty, default: 0
      t.integer :defect_qty, default: 0
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end

    add_index :production_results, :lot_no, unique: true
    add_index :production_results, :created_at
  end
end
