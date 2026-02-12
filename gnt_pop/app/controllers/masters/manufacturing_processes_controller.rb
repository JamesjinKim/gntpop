# frozen_string_literal: true

module Masters
  # 공정 마스터 관리 컨트롤러
  # 슬리팅, 권선, 조립, 몰딩/함침, 가공, 검사, 포장, 출하 등의 공정을 CRUD 관리
  class ManufacturingProcessesController < ApplicationController
    before_action :set_manufacturing_process, only: [ :edit, :update, :destroy ]

    # GET /masters/manufacturing_processes
    def index
      @q = ManufacturingProcess.ransack(params[:q])
      @pagy, @manufacturing_processes = pagy(@q.result.order(:process_order))
    end

    # GET /masters/manufacturing_processes/new
    def new
      @manufacturing_process = ManufacturingProcess.new
    end

    # POST /masters/manufacturing_processes
    def create
      @manufacturing_process = ManufacturingProcess.new(manufacturing_process_params)

      if @manufacturing_process.save
        redirect_to masters_manufacturing_processes_path, notice: "공정이 등록되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /masters/manufacturing_processes/:id/edit
    def edit
    end

    # PATCH/PUT /masters/manufacturing_processes/:id
    def update
      if @manufacturing_process.update(manufacturing_process_params)
        redirect_to masters_manufacturing_processes_path, notice: "공정이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /masters/manufacturing_processes/:id
    def destroy
      @manufacturing_process.destroy!
      redirect_to masters_manufacturing_processes_path, notice: "공정이 삭제되었습니다."
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to masters_manufacturing_processes_path, alert: "관련 설비, 작업자, 생산실적이 있어 삭제할 수 없습니다."
    end

    private

    def set_manufacturing_process
      @manufacturing_process = ManufacturingProcess.find(params[:id])
    end

    def manufacturing_process_params
      params.require(:manufacturing_process).permit(
        :process_code,
        :process_name,
        :process_order,
        :std_cycle_time,
        :is_active
      )
    end
  end
end
