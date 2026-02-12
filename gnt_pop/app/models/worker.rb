# 작업자 마스터 모델
# 공정별 작업자 정보를 관리
class Worker < ApplicationRecord
  # Associations
  belongs_to :manufacturing_process, optional: true
  has_many :production_results, dependent: :restrict_with_error

  # Validations
  validates :employee_number, presence: true, uniqueness: true
  validates :name, presence: true

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[employee_number name manufacturing_process_id is_active created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[manufacturing_process production_results]
  end

  # Scopes
  scope :active, -> { where(is_active: true) }
end
