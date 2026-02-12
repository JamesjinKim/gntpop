# 제조 공정 마스터 모델
# 슬리팅, 권선, 조립, 몰딩/함침, 가공, 검사, 포장, 출하 등의 공정을 관리
class ManufacturingProcess < ApplicationRecord
  # Associations
  has_many :equipments, dependent: :restrict_with_error
  has_many :workers, dependent: :nullify
  has_many :production_results, dependent: :restrict_with_error

  # Validations
  validates :process_code, presence: true, uniqueness: true
  validates :process_name, presence: true
  validates :process_order, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[process_code process_name process_order is_active created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[equipments workers production_results]
  end

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:process_order) }
end
