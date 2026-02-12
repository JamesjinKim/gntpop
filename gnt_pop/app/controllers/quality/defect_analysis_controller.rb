class Quality::DefectAnalysisController < ApplicationController
  def index
    @from = params[:from].present? ? Date.parse(params[:from]) : 30.days.ago.to_date
    @to = params[:to].present? ? Date.parse(params[:to]) : Date.current

    service = DefectAnalysisService.new(@from, @to)
    @summary = service.summary
    @pareto_data = service.pareto_by_defect_code
    @by_process = service.defect_rate_by_process
    @by_product = service.defect_rate_by_product
    @daily_trend = service.daily_defect_trend
  end
end
