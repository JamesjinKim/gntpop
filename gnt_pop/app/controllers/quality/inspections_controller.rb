class Quality::InspectionsController < ApplicationController
  before_action :set_inspection, only: [ :show, :edit, :update, :destroy ]

  def index
    @q = InspectionResult.includes(:worker, :manufacturing_process)
                         .ransack(params[:q])
    @pagy, @inspections = pagy(@q.result.recent, limit: 20)
  end

  def show
    @inspection_items = @inspection.inspection_items.order(:id)
  end

  def new
    @inspection = InspectionResult.new(insp_date: Date.current)
    3.times { @inspection.inspection_items.build }
    load_form_data
  end

  def create
    @inspection = InspectionResult.new(inspection_params)

    if @inspection.save
      redirect_to quality_inspections_path, notice: "검사결과가 등록되었습니다."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    if @inspection.update(inspection_params)
      redirect_to quality_inspections_path, notice: "검사결과가 수정되었습니다."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @inspection.destroy!
    redirect_to quality_inspections_path, notice: "검사결과가 삭제되었습니다."
  end

  private

  def set_inspection
    @inspection = InspectionResult.find(params[:id])
  end

  def inspection_params
    params.require(:inspection_result).permit(
      :lot_no, :insp_type, :insp_date, :worker_id,
      :manufacturing_process_id, :result, :notes,
      inspection_items_attributes: [ :id, :item_name, :spec_value,
                                     :measured_value, :unit, :judgment, :_destroy ]
    )
  end

  def load_form_data
    @workers = Worker.active.order(:name)
    @processes = ManufacturingProcess.active.ordered
  end
end
