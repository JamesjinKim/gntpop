# frozen_string_literal: true

# LOT 추적 컨트롤러
# LOT 번호 기반 생산 이력 검색 및 상세 조회를 담당합니다.
class Productions::LotTrackingController < ApplicationController
  def index
    if params[:lot_no].present?
      @production_result = find_by_lot_no(params[:lot_no].strip)

      if @production_result
        redirect_to productions_lot_tracking_path(lot_no: @production_result.lot_no)
        return
      else
        @lot_no = params[:lot_no]
        @not_found = true
      end
    end

    @recent_results = ProductionResult
      .includes(work_order: :product, manufacturing_process: {})
      .recent
      .limit(10)
  end

  def show
    @production_result = find_by_lot_no(params[:lot_no])

    unless @production_result
      redirect_to productions_lot_tracking_index_path, alert: "LOT 번호를 찾을 수 없습니다."
      return
    end

    @defect_records = @production_result.defect_records.includes(:defect_code)
  end

  private

  def find_by_lot_no(lot_no)
    ProductionResult
      .includes(
        work_order: :product,
        manufacturing_process: {},
        equipment: {},
        worker: {},
        defect_records: :defect_code
      )
      .find_by(lot_no: lot_no)
  end
end
