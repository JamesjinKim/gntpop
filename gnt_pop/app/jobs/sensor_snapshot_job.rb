# LOT 센서 스냅샷 정기 캡처 Job
# Solid Queue에서 실행되는 주기적 센서 데이터 스냅샷 수집
#
# Layer 1 구현 후 recurring.yml에 등록:
#   sensor_snapshot:
#     class: SensorSnapshotJob
#     schedule: every 5 minutes
class SensorSnapshotJob < ApplicationJob
  queue_as :default

  def perform
    # Layer 1 구현 시 실제 센서 데이터 정기 수집 로직 추가
    # 현재 진행 중인 작업지시의 LOT에 periodic 스냅샷 생성
    active_results = ProductionResult
      .joins(:work_order)
      .where(work_orders: { status: :in_progress })

    active_results.find_each do |result|
      LotSensorSnapshotService.capture!(result, snapshot_type: "periodic")
    end
  end
end
