class CreateDefectRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :defect_records do |t|
      t.references :production_result, null: false, foreign_key: true
      t.references :defect_code, null: false, foreign_key: true
      t.integer :defect_qty, default: 1
      t.text :description

      t.timestamps
    end
  end
end
