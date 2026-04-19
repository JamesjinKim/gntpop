# 작업자 마스터 모델
# 공정별 작업자 정보를 관리
class Worker < ApplicationRecord
  # Associations
  belongs_to :tenant
  belongs_to :manufacturing_process, optional: true
  has_many :production_results, dependent: :restrict_with_error

  # Callbacks — 생성 시 Current.tenant 자동 할당
  before_validation :assign_current_tenant, on: :create

  # Validations
  validates :employee_number, presence: true, uniqueness: true
  validates :name, presence: true

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[employee_number name manufacturing_process_id is_active tenant_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[manufacturing_process production_results tenant]
  end

  # Scopes
  scope :active, -> { where(is_active: true) }
  # 멀티테넌시 격리 — 명시적 호출 필수
  scope :for_tenant, ->(t) { where(tenant: t) }

  private

  def assign_current_tenant
    self.tenant_id ||= Current.tenant&.id
  end
end
