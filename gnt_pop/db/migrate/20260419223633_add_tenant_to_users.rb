class AddTenantToUsers < ActiveRecord::Migration[8.1]
  def up
    add_reference :users, :tenant, null: true, foreign_key: true

    # GnT 기본 테넌트가 없으면 생성 (마이그레이션이 시드와 독립적으로 동작하도록)
    execute <<~SQL
      INSERT INTO tenants (code, name, active, created_at, updated_at)
      SELECT 'gnt', '주식회사 지앤티', TRUE, NOW(), NOW()
      WHERE NOT EXISTS (SELECT 1 FROM tenants WHERE code = 'gnt')
    SQL

    gnt_tenant_id = connection.select_value("SELECT id FROM tenants WHERE code = 'gnt'").to_i
    execute("UPDATE users SET tenant_id = #{gnt_tenant_id} WHERE tenant_id IS NULL")

    change_column_null :users, :tenant_id, false
  end

  def down
    remove_reference :users, :tenant, foreign_key: true
  end
end
