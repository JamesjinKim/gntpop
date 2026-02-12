class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :product_code, null: false
      t.string :product_name, null: false
      t.integer :product_group, null: false
      t.text :spec
      t.string :unit, default: "EA"
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :products, :product_code, unique: true
  end
end
