class Quality::SpcController < ApplicationController
  def index
    @item_names = InspectionItem.distinct.pluck(:item_name)
    @item_name = params[:item_name].presence || @item_names.first || "입력전압"
    @from = params[:from].present? ? Date.parse(params[:from]) : 30.days.ago.to_date
    @to = params[:to].present? ? Date.parse(params[:to]) : Date.current

    service = SpcCalculatorService.new(@item_name, @from, @to)
    @xbar_data = service.xbar_chart_data
    @r_data = service.r_chart_data
    @control_limits = service.control_limits
    @capability = service.process_capability
  end
end
