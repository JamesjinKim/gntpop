# frozen_string_literal: true

module Masters
  # 불량코드 마스터 관리 컨트롤러
  # 불량 유형과 설명을 CRUD 관리
  class DefectCodesController < ApplicationController
    before_action :set_defect_code, only: [ :edit, :update, :destroy ]

    # GET /masters/defect_codes
    def index
      @q = DefectCode.ransack(params[:q])
      @pagy, @defect_codes = pagy(@q.result.order(created_at: :desc))
    end

    # GET /masters/defect_codes/new
    def new
      @defect_code = DefectCode.new
    end

    # POST /masters/defect_codes
    def create
      @defect_code = DefectCode.new(defect_code_params)

      if @defect_code.save
        redirect_to masters_defect_codes_path, notice: "불량코드가 등록되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /masters/defect_codes/:id/edit
    def edit
    end

    # PATCH/PUT /masters/defect_codes/:id
    def update
      if @defect_code.update(defect_code_params)
        redirect_to masters_defect_codes_path, notice: "불량코드가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /masters/defect_codes/:id
    def destroy
      @defect_code.destroy!
      redirect_to masters_defect_codes_path, notice: "불량코드가 삭제되었습니다."
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to masters_defect_codes_path, alert: "관련 불량기록이 있어 삭제할 수 없습니다."
    end

    private

    def set_defect_code
      @defect_code = DefectCode.find(params[:id])
    end

    def defect_code_params
      params.require(:defect_code).permit(
        :code,
        :name,
        :description,
        :is_active
      )
    end
  end
end
