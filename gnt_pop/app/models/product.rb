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
  has_many :work_orders, dependent: :restrict_with_error

  # Validations
  validates :product_code, presence: true, uniqueness: true
  validates :product_name, presence: true
  validates :product_group, presence: true

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[product_code product_name product_group is_active created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[work_orders]
  end

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :by_group, ->(group) { where(product_group: group) if group.present? }

  # 제품군 한글명 반환
  def product_group_i18n
    {
      "converter" => "컨버터",
      "transformer_inductor" => "변압기/인덕터",
      "electronic_component" => "전자부품",
      "circuit_board" => "회로기판"
    }[product_group] || product_group
  end
end
