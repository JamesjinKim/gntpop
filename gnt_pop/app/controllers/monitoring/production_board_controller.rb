# frozen_string_literal: true

# 생산현황판 컨트롤러
# 공장 현장 대형 모니터용 전체화면 실시간 현황 화면
class Monitoring::ProductionBoardController < ApplicationController
  layout "fullscreen"

  def index
    service = DashboardQueryService.new(date: Date.current)
    @kpi = service.kpi_data
    @processes = service.process_data
    @recent_results = service.recent_results(limit: 10)
  end
end
