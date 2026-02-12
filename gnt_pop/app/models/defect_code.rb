# 불량 코드 마스터 모델
# 납볼, 미납, 쇼트, 크랙 등 불량 유형을 관리
class DefectCode < ApplicationRecord
  # Associations
  has_many :defect_records, dependent: :restrict_with_error

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[code name is_active created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[defect_records]
  end

  # Scopes
  scope :active, -> { where(is_active: true) }
end
