# frozen_string_literal: true

# 작업지시 관리 컨트롤러
# 제품별 생산 계획을 생성하고 관리하며, 상태를 추적합니다.
class Productions::WorkOrdersController < ApplicationController
  before_action :set_work_order, only: [ :show, :edit, :update, :destroy, :start, :complete, :cancel ]

  # 작업지시 목록 조회
  def index
    @q = WorkOrder.includes(:product).ransack(params[:q])
    @pagy, @work_orders = pagy(@q.result.order(created_at: :desc))
  end

  # 작업지시 상세 조회
  def show
    @production_results = @work_order.production_results
      .includes(:manufacturing_process, :equipment, :worker)
      .order(created_at: :desc)
  end

  # 작업지시 생성 폼
  def new
    @work_order = WorkOrder.new(plan_date: Date.current, priority: 5)
    load_products
  end

  # 작업지시 생성
  def create
    @work_order = WorkOrder.new(work_order_params)
    @work_order.work_order_code = WorkOrderCodeGeneratorService.new.call

    if @work_order.save
      redirect_to productions_work_orders_path, notice: "작업지시가 등록되었습니다."
    else
      load_products
      render :new, status: :unprocessable_entity
    end
  end

  # 작업지시 수정 폼
  def edit
    return redirect_to_index_with_alert unless editable?
    load_products
  end

  # 작업지시 수정
  def update
    return redirect_to_index_with_alert unless editable?

    if @work_order.update(work_order_params)
      redirect_to productions_work_orders_path, notice: "작업지시가 수정되었습니다."
    else
      load_products
      render :edit, status: :unprocessable_entity
    end
  end

  # 작업지시 삭제
  def destroy
    return redirect_to_index_with_alert unless deletable?

    @work_order.destroy!
    redirect_to productions_work_orders_path, notice: "작업지시가 삭제되었습니다."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to productions_work_orders_path, alert: "관련 생산실적이 있어 삭제할 수 없습니다."
  end

  # 작업 시작
  def start
    if @work_order.planned?
      @work_order.in_progress!
      redirect_to productions_work_orders_path, notice: "작업이 시작되었습니다."
    else
      redirect_to productions_work_orders_path, alert: "계획 상태의 작업지시만 시작할 수 있습니다."
    end
  end

  # 작업 완료
  def complete
    if @work_order.in_progress?
      @work_order.completed!
      redirect_to productions_work_orders_path, notice: "작업이 완료되었습니다."
    else
      redirect_to productions_work_orders_path, alert: "진행중 상태의 작업지시만 완료할 수 있습니다."
    end
  end

  # 작업 취소
  def cancel
    if @work_order.in_progress?
      @work_order.cancelled!
      redirect_to productions_work_orders_path, notice: "작업이 취소되었습니다."
    else
      redirect_to productions_work_orders_path, alert: "진행중 상태의 작업지시만 취소할 수 있습니다."
    end
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:id])
  end

  def work_order_params
    params.require(:work_order).permit(:product_id, :order_qty, :plan_date, :priority)
  end

  def load_products
    @products = Product.active.order(:product_code)
  end

  # 수정 가능한 상태인지 확인 (계획 상태만 수정 가능)
  def editable?
    @work_order.planned?
  end

  # 삭제 가능한 상태인지 확인 (계획 상태만 삭제 가능)
  def deletable?
    @work_order.planned?
  end

  def redirect_to_index_with_alert
    redirect_to productions_work_orders_path, alert: "계획 상태의 작업지시만 수정/삭제할 수 있습니다."
  end
end
