class AddTenantToEquipments < ActiveRecord::Migration[8.1]
  def up
    # equipments 테이블명 주의: Rails inflection이 "equipment"를 uncountable로 처리
    add_reference :equipments, :tenant, null: true, foreign_key: true

    gnt_tenant_id = connection.select_value("SELECT id FROM tenants WHERE code = 'gnt'").to_i
    raise "GnT tenant not found" if gnt_tenant_id.zero?

    execute("UPDATE equipments SET tenant_id = #{gnt_tenant_id} WHERE tenant_id IS NULL")

    change_column_null :equipments, :tenant_id, false
  end

  def down
    remove_reference :equipments, :tenant, foreign_key: true
  end
end
