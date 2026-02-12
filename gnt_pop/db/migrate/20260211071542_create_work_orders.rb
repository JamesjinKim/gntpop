class CreateWorkOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :work_orders do |t|
      t.string :work_order_code, null: false
      t.references :product, null: false, foreign_key: true
      t.integer :order_qty, null: false
      t.date :plan_date, null: false
      t.integer :status, default: 0
      t.integer :priority, default: 5

      t.timestamps
    end

    add_index :work_orders, :work_order_code, unique: true
    add_index :work_orders, :plan_date
    add_index :work_orders, :status
  end
end
