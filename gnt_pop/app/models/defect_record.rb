# 불량 기록 모델
# 생산 실적별 불량 유형과 수량을 상세 기록
class DefectRecord < ApplicationRecord
  # Associations
  belongs_to :production_result
  belongs_to :defect_code

  # Validations
  validates :defect_qty, numericality: { only_integer: true, greater_than: 0 }
end
