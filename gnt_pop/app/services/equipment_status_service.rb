# frozen_string_literal: true

# 설비 상태 집계 및 필터 서비스
# 설비상태 대시보드에서 사용하는 요약/필터/최근LOT 조회
#
# 사용 예시:
#   service = EquipmentStatusService.new
#   summary = service.summary
#   equipments = service.filtered_list(status: "run")
#   lot = service.recent_lot(equipment)
class EquipmentStatusService
  # 설비 상태별 수 요약
  # @return [Hash] { run: 3, idle: 2, down: 1, pm: 0, total: 6 }
  def summary
    active = Equipment.active
    {
      run: active.where(status: :run).count,
      idle: active.where(status: :idle).count,
      down: active.where(status: :down).count,
      pm: active.where(status: :pm).count,
      total: active.count
    }
  end

  # 상태별 필터링된 설비 목록
  # @param status [String, nil] 필터 상태 (nil이면 전체)
  # @return [ActiveRecord::Relation<Equipment>]
  def filtered_list(status: nil)
    scope = Equipment.active.includes(:manufacturing_process)
    scope = scope.where(status: status) if status.present?
    scope.order(:equipment_name)
  end

  # 설비의 최근 생산 LOT 번호 조회
  # @param equipment [Equipment] 설비
  # @return [String, nil] 최근 LOT 번호 또는 nil
  def recent_lot(equipment)
    equipment.production_results
             .order(created_at: :desc)
             .limit(1)
             .pick(:lot_no)
  end
end
