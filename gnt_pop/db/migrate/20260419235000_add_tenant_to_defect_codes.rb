class AddTenantToDefectCodes < ActiveRecord::Migration[8.1]
  def up
    add_reference :defect_codes, :tenant, null: true, foreign_key: true

    gnt_tenant_id = connection.select_value("SELECT id FROM tenants WHERE code = 'gnt'").to_i
    raise "GnT tenant not found" if gnt_tenant_id.zero?

    # 기존 DefectCode(D01~D10)는 GnT 소속으로 backfill
    execute("UPDATE defect_codes SET tenant_id = #{gnt_tenant_id} WHERE tenant_id IS NULL")

    change_column_null :defect_codes, :tenant_id, false
  end

  def down
    remove_reference :defect_codes, :tenant, foreign_key: true
  end
end
