class DashboardController < ApplicationController
  def index
    service = DashboardQueryService.new(date: Date.current)
    @kpi = service.kpi_data
    @processes = service.process_data
    @equipments = service.equipment_data
    @recent_results = service.recent_results(limit: 5)
    @notifications = load_notifications
  end

  private

  # TODO: Notification 모델 생성 후 실제 데이터로 대체
  def load_notifications
    recent_work_orders = WorkOrder.where(status: :completed)
                                  .order(updated_at: :desc)
                                  .limit(3)

    notifications = recent_work_orders.map do |wo|
      {
        type: "success",
        message: "작업지시 #{wo.work_order_code} 완료",
        time: time_ago_in_words(wo.updated_at)
      }
    end

    pm_equipments = Equipment.where(status: :pm)
    pm_equipments.each do |eq|
      notifications << {
        type: "warning",
        message: "#{eq.equipment_name} 예방정비 중",
        time: "진행중"
      }
    end

    notifications.first(5)
  end

  def time_ago_in_words(time)
    diff = Time.current - time
    case diff
    when 0..59 then "방금 전"
    when 60..3599 then "#{(diff / 60).to_i}분 전"
    when 3600..86399 then "#{(diff / 3600).to_i}시간 전"
    else "#{(diff / 86400).to_i}일 전"
    end
  end
end
