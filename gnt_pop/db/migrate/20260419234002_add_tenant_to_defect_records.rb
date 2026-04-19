class AddTenantToDefectRecords < ActiveRecord::Migration[8.1]
  def up
    add_reference :defect_records, :tenant, null: true, foreign_key: true

    gnt_tenant_id = connection.select_value("SELECT id FROM tenants WHERE code = 'gnt'").to_i
    raise "GnT tenant not found" if gnt_tenant_id.zero?

    # DefectRecord는 ProductionResult 종속이지만, 일관성/스코핑 단순화 위해 직접 tenant_id 보유
    execute("UPDATE defect_records SET tenant_id = #{gnt_tenant_id} WHERE tenant_id IS NULL")

    change_column_null :defect_records, :tenant_id, false
  end

  def down
    remove_reference :defect_records, :tenant, foreign_key: true
  end
end
