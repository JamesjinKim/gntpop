# 불량 기록 모델
# 생산 실적별 불량 유형과 수량을 상세 기록
class DefectRecord < ApplicationRecord
  # Associations
  belongs_to :tenant
  belongs_to :production_result
  belongs_to :defect_code

  # Callbacks — parent(ProductionResult)의 tenant 상속
  before_validation :assign_tenant_from_parent, on: :create

  # Validations
  validates :defect_qty, numericality: { only_integer: true, greater_than: 0 }

  # Scopes
  scope :for_tenant, ->(t) { where(tenant: t) }

  private

  def assign_tenant_from_parent
    self.tenant_id ||= production_result&.tenant_id || Current.tenant&.id
  end
end
