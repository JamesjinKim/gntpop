# 대시보드 컨트롤러
# 생산 현황 대시보드의 모든 데이터를 준비하여 View에 전달합니다
class DashboardController < ApplicationController
  # 메인 대시보드 화면
  # KPI, 공정 현황, 설비 상태, 최근 실적, 알림 데이터를 로드합니다
  def index
    load_kpi_data
    load_process_data
    load_equipment_data
    load_recent_results
    load_notifications
  end

  private

  # KPI 요약 데이터를 로드합니다
  # TODO: 실제 DB 데이터로 대체 필요
  def load_kpi_data
    @kpi = {
      production: {
        actual: 1248,
        target: 1500,
        rate: 83.2
      },
      defect: {
        rate: 1.2,
        target: 2.0,
        trend: 0.3,
        good_count: 1233,
        defect_count: 15
      },
      equipment: {
        rate: 92.5,
        running: 8,
        idle: 1,
        error: 0,
        pm: 1
      },
      work_order: {
        in_progress: 5,
        planned: 3,
        completed: 12
      }
    }
  end

  # 공정별 생산 현황 데이터를 로드합니다
  # TODO: 실제 DB 데이터로 대체 필요
  def load_process_data
    @processes = [
      { name: "슬리팅", progress: 95, target: 200, actual: 190, status: "running" },
      { name: "권선", progress: 78, target: 180, actual: 140, status: "running" },
      { name: "조립", progress: 65, target: 150, actual: 98, status: "running" },
      { name: "몰딩/함침", progress: 45, target: 120, actual: 54, status: "running" },
      { name: "가공", progress: 82, target: 100, actual: 82, status: "idle" },
      { name: "검사", progress: 88, target: 180, actual: 158, status: "running" },
      { name: "포장", progress: 92, target: 170, actual: 156, status: "running" },
      { name: "출하", progress: 100, target: 150, actual: 150, status: "completed" }
    ]
  end

  # 설비 상태 데이터를 로드합니다
  # TODO: 실제 DB 데이터로 대체 필요
  def load_equipment_data
    @equipments = [
      { name: "슬리터 #1", status: "run", time: "2h 30m" },
      { name: "권선기 #1", status: "run", time: "1h 45m" },
      { name: "권선기 #2", status: "run", time: "3h 10m" },
      { name: "조립기 #1", status: "idle", time: "대기중" },
      { name: "몰딩기 #1", status: "run", time: "45m" },
      { name: "검사기 #1", status: "run", time: "2h 5m" },
      { name: "포장기 #1", status: "pm", time: "PM중" },
      { name: "가공기 #1", status: "run", time: "1h 20m" }
    ]
  end

  # 최근 생산실적 데이터를 로드합니다
  # TODO: 실제 DB 데이터로 대체 필요
  def load_recent_results
    @recent_results = [
      { wo: "WO-20260209-001", process: "권선", qty: 50, time: "10:32" },
      { wo: "WO-20260209-002", process: "검사", qty: 48, time: "10:15" },
      { wo: "WO-20260209-001", process: "조립", qty: 45, time: "09:58" },
      { wo: "WO-20260209-003", process: "슬리팅", qty: 100, time: "09:42" },
      { wo: "WO-20260209-002", process: "포장", qty: 52, time: "09:30" }
    ]
  end

  # 알림 및 이벤트 데이터를 로드합니다
  # TODO: 실제 DB 데이터로 대체 필요
  def load_notifications
    @notifications = [
      { type: "success", message: "작업지시 WO-20260209-001 완료", time: "10분 전" },
      { type: "warning", message: "권선기 #2 예방정비 예정", time: "내일 09:00 예정" },
      { type: "info", message: "신규 작업지시 3건 등록됨", time: "30분 전" },
      { type: "default", message: "일일 생산 보고서 생성 완료", time: "어제 18:00" }
    ]
  end
end
