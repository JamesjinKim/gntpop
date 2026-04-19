class AddTenantToProducts < ActiveRecord::Migration[8.1]
  def up
    add_reference :products, :tenant, null: true, foreign_key: true

    # 기존 Product는 GnT 테넌트로 backfill
    gnt_tenant_id = connection.select_value("SELECT id FROM tenants WHERE code = 'gnt'").to_i
    raise "GnT tenant not found" if gnt_tenant_id.zero?

    execute("UPDATE products SET tenant_id = #{gnt_tenant_id} WHERE tenant_id IS NULL")

    change_column_null :products, :tenant_id, false
  end

  def down
    remove_reference :products, :tenant, foreign_key: true
  end
end
