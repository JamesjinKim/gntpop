class AddTenantToInspectionItems < ActiveRecord::Migration[8.1]
  def up
    add_reference :inspection_items, :tenant, null: true, foreign_key: true

    gnt_tenant_id = connection.select_value("SELECT id FROM tenants WHERE code = 'gnt'").to_i
    raise "GnT tenant not found" if gnt_tenant_id.zero?

    # InspectionResult 기반 backfill (parent의 tenant_id 상속)
    execute(<<~SQL)
      UPDATE inspection_items
      SET tenant_id = COALESCE(
        (SELECT tenant_id FROM inspection_results WHERE inspection_results.id = inspection_items.inspection_result_id),
        #{gnt_tenant_id}
      )
      WHERE tenant_id IS NULL
    SQL

    change_column_null :inspection_items, :tenant_id, false
  end

  def down
    remove_reference :inspection_items, :tenant, foreign_key: true
  end
end
