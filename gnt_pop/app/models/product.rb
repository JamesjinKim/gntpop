# 제품 마스터 모델
# 컨버터, 변압기/인덕터, 전자부품, 회로기판 등을 관리
class Product < ApplicationRecord
  # Enums
  enum :product_group, {
    converter: 0,
    transformer_inductor: 1,
    electronic_component: 2,
    circuit_board: 3
  }

  # Associations
  belongs_to :tenant
  has_many :work_orders, dependent: :restrict_with_error

  # Callbacks — 생성 시 Current.tenant 자동 할당 (누락 방지)
  before_validation :assign_current_tenant, on: :create

  # Validations
  validates :product_code, presence: true, uniqueness: true
  validates :product_name, presence: true
  validates :product_group, presence: true

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[product_code product_name product_group is_active tenant_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[work_orders tenant]
  end

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :by_group, ->(group) { where(product_group: group) if group.present? }
  # 멀티테넌시 격리 — 명시적 호출 필수 (default_scope 미사용, 2-3개 경험 후 재평가 예정)
  scope :for_tenant, ->(t) { where(tenant: t) }

  # 제품군 한글명 반환
  def product_group_i18n
    {
      "converter" => "컨버터",
      "transformer_inductor" => "변압기/인덕터",
      "electronic_component" => "전자부품",
      "circuit_board" => "회로기판"
    }[product_group] || product_group
  end

  private

  def assign_current_tenant
    self.tenant_id ||= Current.tenant&.id
  end
end
