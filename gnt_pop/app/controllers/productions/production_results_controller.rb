# frozen_string_literal: true

# 생산실적 관리 컨트롤러
# LOT별 생산 수량, 불량 수량, 작업 시간을 입력하고 관리합니다.
class Productions::ProductionResultsController < ApplicationController
  before_action :set_production_result, only: [ :show, :edit, :update, :destroy ]

  # 생산실적 목록 조회
  def index
    @q = ProductionResult
      .includes(:work_order, :manufacturing_process, :equipment, :worker)
      .ransack(params[:q])
    @pagy, @production_results = pagy(@q.result.order(created_at: :desc))
  end

  # 생산실적 상세 조회
  def show
    @defect_records = @production_result.defect_records.includes(:defect_code).order(created_at: :asc)
  end

  # 생산실적 입력 폼
  def new
    @production_result = ProductionResult.new(
      start_time: Time.current.beginning_of_hour,
      end_time: Time.current
    )
    load_form_data
  end

  # 생산실적 생성
  def create
    @production_result = ProductionResult.new(production_result_params)
    work_order = WorkOrder.find(@production_result.work_order_id)
    @production_result.lot_no = LotGeneratorService.new(work_order).call

    if @production_result.save
      save_defect_records(@production_result) if @production_result.defect_qty.positive?
      work_order.in_progress! if work_order.planned?

      redirect_to productions_production_results_path,
        notice: "생산실적이 등록되었습니다. (LOT: #{@production_result.lot_no})"
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  # 생산실적 수정 폼
  def edit
    load_form_data
  end

  # 생산실적 수정
  def update
    if @production_result.update(production_result_params)
      redirect_to productions_production_results_path, notice: "생산실적이 수정되었습니다."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  # 생산실적 삭제
  def destroy
    @production_result.destroy!
    redirect_to productions_production_results_path, notice: "생산실적이 삭제되었습니다."
  end

  private

  def set_production_result
    @production_result = ProductionResult.find(params[:id])
  end

  def production_result_params
    params.require(:production_result).permit(
      :work_order_id,
      :manufacturing_process_id,
      :equipment_id,
      :worker_id,
      :good_qty,
      :defect_qty,
      :start_time,
      :end_time
    )
  end

  # 폼에 필요한 데이터 로드
  def load_form_data
    @work_orders = WorkOrder
      .where(status: [ :planned, :in_progress ])
      .includes(:product)
      .order(created_at: :desc)
    @processes = ManufacturingProcess.active.ordered
    @equipments = Equipment.active.order(:equipment_code)
    @workers = Worker.active.order(:name)
    @defect_codes = DefectCode.active.order(:code)
  end

  # 불량 기록 저장
  # 폼에서 전달된 불량 정보를 파싱하여 DefectRecord로 저장합니다.
  def save_defect_records(production_result)
    defect_params = params[:defect_records]
    return unless defect_params.is_a?(ActionController::Parameters) || defect_params.is_a?(Hash)

    defect_params.each do |_, record|
      next if record[:defect_code_id].blank? || record[:defect_qty].to_i <= 0

      production_result.defect_records.create!(
        defect_code_id: record[:defect_code_id],
        defect_qty: record[:defect_qty],
        description: record[:description]
      )
    end
  end
end
