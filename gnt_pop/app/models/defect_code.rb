# 불량 코드 마스터 모델
# 납볼, 미납, 쇼트, 크랙 등 불량 유형을 관리
class DefectCode < ApplicationRecord
  # Associations
  belongs_to :tenant
  has_many :defect_records, dependent: :restrict_with_error

  # Callbacks — 생성 시 Current.tenant 자동 할당
  before_validation :assign_current_tenant, on: :create

  # Validations
  # code uniqueness는 테넌트 범위 안에서만 — 같은 코드(D01)를 여러 회사가 사용 가능
  validates :code, presence: true, uniqueness: { scope: :tenant_id }
  validates :name, presence: true

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[code name is_active tenant_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[defect_records tenant]
  end

  # Scopes
  scope :active, -> { where(is_active: true) }
  # 멀티테넌시 격리 — 명시적 호출 필수 (테넌트별 분리, 업종별 불량 유형 다름)
  scope :for_tenant, ->(t) { where(tenant: t) }

  private

  def assign_current_tenant
    self.tenant_id ||= Current.tenant&.id
  end
end
