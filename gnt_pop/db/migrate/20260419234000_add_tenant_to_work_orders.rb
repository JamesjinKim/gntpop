class AddTenantToWorkOrders < ActiveRecord::Migration[8.1]
  def up
    add_reference :work_orders, :tenant, null: true, foreign_key: true

    gnt_tenant_id = connection.select_value("SELECT id FROM tenants WHERE code = 'gnt'").to_i
    raise "GnT tenant not found" if gnt_tenant_id.zero?

    execute("UPDATE work_orders SET tenant_id = #{gnt_tenant_id} WHERE tenant_id IS NULL")

    change_column_null :work_orders, :tenant_id, false
  end

  def down
    remove_reference :work_orders, :tenant, foreign_key: true
  end
end
