# frozen_string_literal: true

# 작업지시 코드 자동 생성 서비스
# 형식: WO-YYYYMMDD-NNN (예: WO-20260211-001)
#
# 사용 예시:
#   wo_code = WorkOrderCodeGeneratorService.new.call
#   # => "WO-20260211-001"
class WorkOrderCodeGeneratorService
  def call
    date_part = Date.current.strftime("%Y%m%d")
    sequence = next_sequence(date_part)

    "WO-#{date_part}-#{sequence}"
  end

  private

  # 해당 날짜에 대한 다음 순번을 계산
  # @param date_part [String] YYYYMMDD 형식의 날짜
  # @return [String] 3자리 숫자 문자열 (예: "001", "002")
  def next_sequence(date_part)
    prefix = "WO-#{date_part}-"

    # 해당 prefix로 시작하는 마지막 작업지시 코드 조회
    last_work_order = WorkOrder
      .where("work_order_code LIKE ?", "#{prefix}%")
      .order(:work_order_code)
      .last

    if last_work_order
      last_sequence = last_work_order.work_order_code.split("-").last.to_i
      format("%03d", last_sequence + 1)
    else
      "001"
    end
  end
end
