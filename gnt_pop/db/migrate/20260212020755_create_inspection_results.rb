class CreateInspectionResults < ActiveRecord::Migration[8.1]
  def change
    create_table :inspection_results do |t|
      t.string :lot_no, null: false
      t.integer :insp_type, null: false
      t.date :insp_date, null: false
      t.references :worker, foreign_key: true
      t.references :manufacturing_process, foreign_key: true
      t.integer :result, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :inspection_results, :lot_no
    add_index :inspection_results, :insp_type
    add_index :inspection_results, :insp_date
  end
end
