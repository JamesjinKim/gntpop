class CreateWorkers < ActiveRecord::Migration[8.1]
  def change
    create_table :workers do |t|
      t.string :employee_number, null: false
      t.string :name, null: false
      t.references :manufacturing_process, foreign_key: true
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :workers, :employee_number, unique: true
  end
end
