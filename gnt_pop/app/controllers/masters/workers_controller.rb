# frozen_string_literal: true

module Masters
  # 작업자 마스터 관리 컨트롤러
  # 작업자의 정보와 소속 공정을 CRUD 관리
  class WorkersController < ApplicationController
    before_action :set_worker, only: [ :edit, :update, :destroy ]

    # GET /masters/workers
    def index
      @q = Worker.ransack(params[:q])
      @pagy, @workers = pagy(@q.result.includes(:manufacturing_process).order(created_at: :desc))
    end

    # GET /masters/workers/new
    def new
      @worker = Worker.new
    end

    # POST /masters/workers
    def create
      @worker = Worker.new(worker_params)

      if @worker.save
        redirect_to masters_workers_path, notice: "작업자가 등록되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /masters/workers/:id/edit
    def edit
    end

    # PATCH/PUT /masters/workers/:id
    def update
      if @worker.update(worker_params)
        redirect_to masters_workers_path, notice: "작업자가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /masters/workers/:id
    def destroy
      @worker.destroy!
      redirect_to masters_workers_path, notice: "작업자가 삭제되었습니다."
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to masters_workers_path, alert: "관련 생산실적이 있어 삭제할 수 없습니다."
    end

    private

    def set_worker
      @worker = Worker.find(params[:id])
    end

    def worker_params
      params.require(:worker).permit(
        :employee_number,
        :name,
        :manufacturing_process_id,
        :is_active
      )
    end
  end
end
