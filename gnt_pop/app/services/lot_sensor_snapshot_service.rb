# frozen_string_literal: true

# LOT-센서 바인딩 스냅샷 서비스
# LOT 생산 시작/종료 시점의 환경 센서 데이터를 스냅샷으로 기록
#
# 사용 예시:
#   LotSensorSnapshotService.capture!(production_result, snapshot_type: "start")
#   LotSensorSnapshotService.capture_end!(production_result)
class LotSensorSnapshotService
  def self.capture!(production_result, snapshot_type:)
    sensor_data = collect_sensor_data(production_result)
    safety_data = collect_safety_data(production_result)

    production_result.lot_sensor_snapshots.create!(
      lot_no: production_result.lot_no,
      snapshot_type: snapshot_type,
      sensor_data: sensor_data,
      safety_data: safety_data
    )
  end

  def self.capture_end!(production_result)
    start_snapshot = production_result.lot_sensor_snapshots.starts.first
    sensor_data = collect_sensor_data(production_result)
    safety_data = collect_safety_data(production_result)
    statistics = calculate_statistics(production_result, start_snapshot)

    production_result.lot_sensor_snapshots.create!(
      lot_no: production_result.lot_no,
      snapshot_type: "end",
      sensor_data: sensor_data,
      safety_data: safety_data,
      statistics: statistics
    )
  end

  private

  def self.collect_sensor_data(_production_result)
    # TODO: Layer 1 구현 시 InfluxDB에서 실제 센서 데이터 조회
    {}
  end

  def self.collect_safety_data(_production_result)
    # TODO: Layer 2 구현 시 실제 안전 상태 조회
    { safety_status: "not_configured", active_alerts: [] }
  end

  def self.calculate_statistics(_production_result, _start_snapshot)
    # TODO: Layer 1 구현 시 InfluxDB 기간 통계 계산
    {}
  end
end
