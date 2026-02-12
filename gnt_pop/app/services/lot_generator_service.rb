# frozen_string_literal: true

# LOT 번호 자동 생성 서비스
# 형식: L-YYYYMMDD-제품코드-NNN (예: L-20260211-CVT-001-001)
#
# 사용 예시:
#   lot_no = LotGeneratorService.new(work_order).call
#   # => "L-20260211-CVT-001-001"
class LotGeneratorService
  def initialize(work_order)
    @work_order = work_order
    @product = work_order.product
  end

  def call
    date_part = Date.current.strftime("%Y%m%d")
    product_part = @product.product_code
    sequence = next_sequence(date_part, product_part)

    "L-#{date_part}-#{product_part}-#{sequence}"
  end

  private

  # 해당 날짜와 제품코드에 대한 다음 순번을 계산
  # @param date_part [String] YYYYMMDD 형식의 날짜
  # @param product_part [String] 제품 코드 (예: CVT-001)
  # @return [String] 3자리 숫자 문자열 (예: "001", "002")
  def next_sequence(date_part, product_part)
    prefix = "L-#{date_part}-#{product_part}-"

    # 해당 prefix로 시작하는 마지막 LOT 번호 조회
    last_production = ProductionResult
      .where("lot_no LIKE ?", "#{prefix}%")
      .order(:lot_no)
      .last

    if last_production
      last_sequence = last_production.lot_no.split("-").last.to_i
      format("%03d", last_sequence + 1)
    else
      "001"
    end
  end
end
