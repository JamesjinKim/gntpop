# frozen_string_literal: true

module Masters
  # 설비 마스터 관리 컨트롤러
  # 생산 설비의 정보와 상태를 CRUD 관리
  class EquipmentsController < ApplicationController
    before_action :set_equipment, only: [ :edit, :update, :destroy ]

    # GET /masters/equipments
    def index
      @q = Equipment.ransack(params[:q])
      @pagy, @equipments = pagy(@q.result.includes(:manufacturing_process).order(created_at: :desc))
    end

    # GET /masters/equipments/new
    def new
      @equipment = Equipment.new
    end

    # POST /masters/equipments
    def create
      @equipment = Equipment.new(equipment_params)

      if @equipment.save
        redirect_to masters_equipments_path, notice: "설비가 등록되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /masters/equipments/:id/edit
    def edit
    end

    # PATCH/PUT /masters/equipments/:id
    def update
      if @equipment.update(equipment_params)
        redirect_to masters_equipments_path, notice: "설비가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /masters/equipments/:id
    def destroy
      @equipment.destroy!
      redirect_to masters_equipments_path, notice: "설비가 삭제되었습니다."
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to masters_equipments_path, alert: "관련 생산실적이 있어 삭제할 수 없습니다."
    end

    private

    def set_equipment
      @equipment = Equipment.find(params[:id])
    end

    def equipment_params
      params.require(:equipment).permit(
        :equipment_code,
        :equipment_name,
        :manufacturing_process_id,
        :location,
        :status,
        :is_active
      )
    end
  end
end
