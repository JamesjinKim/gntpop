class AddTenantToLotSensorSnapshots < ActiveRecord::Migration[8.1]
  def up
    add_reference :lot_sensor_snapshots, :tenant, null: true, foreign_key: true

    gnt_tenant_id = connection.select_value("SELECT id FROM tenants WHERE code = 'gnt'").to_i
    raise "GnT tenant not found" if gnt_tenant_id.zero?

    # ProductionResult 기반 backfill
    execute(<<~SQL)
      UPDATE lot_sensor_snapshots
      SET tenant_id = COALESCE(
        (SELECT tenant_id FROM production_results WHERE production_results.id = lot_sensor_snapshots.production_result_id),
        #{gnt_tenant_id}
      )
      WHERE tenant_id IS NULL
    SQL

    change_column_null :lot_sensor_snapshots, :tenant_id, false
  end

  def down
    remove_reference :lot_sensor_snapshots, :tenant, foreign_key: true
  end
end
