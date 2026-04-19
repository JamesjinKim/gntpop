# 제조 공정 마스터 모델
# 슬리팅, 권선, 조립, 몰딩/함침, 가공, 검사, 포장, 출하 등의 공정을 관리
class ManufacturingProcess < ApplicationRecord
  # Associations
  belongs_to :tenant
  has_many :equipments, dependent: :restrict_with_error
  has_many :workers, dependent: :nullify
  has_many :production_results, dependent: :restrict_with_error

  # Callbacks — 생성 시 Current.tenant 자동 할당
  before_validation :assign_current_tenant, on: :create

  # Validations
  validates :process_code, presence: true, uniqueness: true
  validates :process_name, presence: true
  validates :process_order, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[process_code process_name process_order is_active tenant_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[equipments workers production_results tenant]
  end

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:process_order) }
  # 멀티테넌시 격리 — 명시적 호출 필수 (default_scope 미사용)
  scope :for_tenant, ->(t) { where(tenant: t) }

  private

  def assign_current_tenant
    self.tenant_id ||= Current.tenant&.id
  end
end
