class CreateLotSensorSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :lot_sensor_snapshots do |t|
      t.references :production_result, null: false, foreign_key: true
      t.string :lot_no, null: false
      t.string :snapshot_type              # "start", "end", "periodic"
      t.jsonb :sensor_data, default: {}    # 전체 센서 스냅샷
      t.jsonb :safety_data, default: {}    # 안전 스냅샷
      t.jsonb :statistics, default: {}     # 기간 통계 (end 시)
      t.timestamps
    end

    add_index :lot_sensor_snapshots, [:lot_no, :snapshot_type]
    add_index :lot_sensor_snapshots, :created_at
  end
end
