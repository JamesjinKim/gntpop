# frozen_string_literal: true

# 설비상태 컨트롤러
# 설비별 가동 상태, 위치, 최근 생산 이력 대시보드
class Monitoring::EquipmentStatusController < ApplicationController
  def index
    service = EquipmentStatusService.new
    @summary = service.summary
    @equipments = service.filtered_list(status: params[:status])
    @current_filter = params[:status]
  end

  def change_status
    @equipment = Equipment.find(params[:id])
    if @equipment.update(status: params[:status])
      redirect_to monitoring_equipment_status_index_path(status: params[:filter]),
                  notice: "#{@equipment.equipment_name} 상태가 '#{@equipment.status_i18n}'(으)로 변경되었습니다."
    else
      redirect_to monitoring_equipment_status_index_path(status: params[:filter]),
                  alert: "상태 변경에 실패했습니다."
    end
  end
end
