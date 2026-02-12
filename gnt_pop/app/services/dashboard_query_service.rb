# frozen_string_literal: true

# 대시보드 KPI 집계 쿼리 서비스
# DashboardController의 목업 데이터를 실제 DB 쿼리로 대체
#
# 사용 예시:
#   service = DashboardQueryService.new(date: Date.current)
#   kpis = service.kpi_data
#   processes = service.process_data
#   equipments = service.equipment_data
#   recent = service.recent_results(limit: 5)
class DashboardQueryService
  # 일일 생산 목표량 (향후 설정 테이블로 이관 가능)
  DEFAULT_DAILY_TARGET = 200

  def initialize(date: Date.current)
    @date = date
  end

  # 4가지 핵심 KPI 데이터 반환
  # @return [Hash] 생산, 불량, 설비, 작업지시 KPI
  def kpi_data
    {
      production: production_kpi,
      defect: defect_kpi,
      equipment: equipment_kpi,
      work_order: work_order_kpi
    }
  end

  # 공정별 진행 상황 데이터
  # @return [Array<Hash>] 공정명, 진행률, 목표, 실적, 상태
  def process_data
    ManufacturingProcess.active.ordered.map do |process|
      results = process.production_results.where(created_at: @date.all_day)
      actual = results.sum(:good_qty)
      target = daily_target_for(process)
      equipment_running = process.equipments.where(status: :run).exists?

      {
        name: process.process_name,
        progress: calculate_progress_rate(actual, target),
        target: target,
        actual: actual,
        status: equipment_running ? "running" : "idle"
      }
    end
  end

  # 설비 상태 데이터
  # @return [Array<Hash>] 설비명, 상태, 가동 시간
  def equipment_data
    Equipment.active.includes(:manufacturing_process).map do |equipment|
      {
        name: equipment.equipment_name,
        status: equipment.status,
        time: equipment_elapsed_time(equipment)
      }
    end
  end

  # 최근 생산 실적 목록
  # @param limit [Integer] 조회할 개수 (기본값: 5)
  # @return [Array<Hash>] 작업지시, 공정, 수량, 시각
  def recent_results(limit: 5)
    ProductionResult
      .includes(:work_order, :manufacturing_process)
      .order(created_at: :desc)
      .limit(limit)
      .map do |result|
        {
          wo: result.work_order.work_order_code,
          process: result.manufacturing_process.process_name,
          qty: result.good_qty,
          time: result.created_at.strftime("%H:%M")
        }
      end
  end

  private

  # 생산 KPI 계산
  # @return [Hash] 실적, 목표, 달성률
  def production_kpi
    today_results = ProductionResult.where(created_at: @date.all_day)
    actual = today_results.sum(:good_qty)
    target = WorkOrder.where(plan_date: @date).sum(:order_qty)

    # 0으로 나누기 방지
    target = 1 if target.zero?

    {
      actual: actual,
      target: target,
      rate: calculate_achievement_rate(actual, target)
    }
  end

  # 불량 KPI 계산
  # @return [Hash] 불량률, 목표불량률, 양품수, 불량수
  def defect_kpi
    today_results = ProductionResult.where(created_at: @date.all_day)
    good_count = today_results.sum(:good_qty)
    defect_count = today_results.sum(:defect_qty)
    total = good_count + defect_count

    defect_rate = calculate_defect_rate(defect_count, total)

    {
      rate: defect_rate,
      target: 2.0, # 목표 불량률 2%
      good_count: good_count,
      defect_count: defect_count
    }
  end

  # 설비 KPI 계산
  # @return [Hash] 가동률, 가동중, 대기, 고장, 점검 설비 수
  def equipment_kpi
    active_equipments = Equipment.active
    running_count = active_equipments.where(status: :run).count
    total_count = active_equipments.count

    operation_rate = calculate_operation_rate(running_count, total_count)

    {
      rate: operation_rate,
      running: running_count,
      idle: active_equipments.where(status: :idle).count,
      error: active_equipments.where(status: :down).count,
      pm: active_equipments.where(status: :pm).count
    }
  end

  # 작업지시 KPI 계산
  # @return [Hash] 진행중, 예정, 완료 작업지시 수
  def work_order_kpi
    {
      in_progress: WorkOrder.where(status: :in_progress).count,
      planned: WorkOrder.where(status: :planned).count,
      completed: WorkOrder.where(status: :completed, updated_at: @date.all_day).count
    }
  end

  # 공정별 일일 목표 수량 계산
  # @param process [ManufacturingProcess] 공정
  # @return [Integer] 목표 수량
  def daily_target_for(_process)
    # TODO: 향후 공정별 목표 설정 테이블에서 조회하도록 개선
    DEFAULT_DAILY_TARGET
  end

  # 설비 가동 경과 시간 계산
  # @param equipment [Equipment] 설비
  # @return [String] 경과 시간 문자열 (예: "2h 30m", "45m", "대기중")
  def equipment_elapsed_time(equipment)
    last_result = equipment.production_results.order(created_at: :desc).first
    return "대기중" unless last_result&.start_time

    elapsed_seconds = Time.current - last_result.start_time
    format_elapsed_time(elapsed_seconds)
  end

  # 경과 시간을 읽기 쉬운 형식으로 변환
  # @param seconds [Float] 초 단위 경과 시간
  # @return [String] 형식화된 시간 문자열
  def format_elapsed_time(seconds)
    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i

    hours.positive? ? "#{hours}h #{minutes}m" : "#{minutes}m"
  end

  # 진행률 계산 (0~100%)
  # @param actual [Integer] 실적
  # @param target [Integer] 목표
  # @return [Integer] 진행률 (%)
  def calculate_progress_rate(actual, target)
    return 0 unless target.positive?

    ((actual.to_f / target) * 100).round(0)
  end

  # 달성률 계산 (소수점 1자리)
  # @param actual [Integer] 실적
  # @param target [Integer] 목표
  # @return [Float] 달성률 (%)
  def calculate_achievement_rate(actual, target)
    return 0.0 unless target.positive?

    ((actual.to_f / target) * 100).round(1)
  end

  # 불량률 계산 (소수점 1자리)
  # @param defect_count [Integer] 불량 수
  # @param total_count [Integer] 총 생산 수
  # @return [Float] 불량률 (%)
  def calculate_defect_rate(defect_count, total_count)
    return 0.0 unless total_count.positive?

    ((defect_count.to_f / total_count) * 100).round(1)
  end

  # 가동률 계산 (소수점 1자리)
  # @param running_count [Integer] 가동 중인 설비 수
  # @param total_count [Integer] 전체 설비 수
  # @return [Float] 가동률 (%)
  def calculate_operation_rate(running_count, total_count)
    return 0.0 unless total_count.positive?

    ((running_count.to_f / total_count) * 100).round(1)
  end
end
