# 설비 마스터 모델
# 생산 설비의 정보와 상태를 관리
class Equipment < ApplicationRecord
  self.table_name = "equipments"
  # Enums
  enum :status, {
    idle: 0,    # 대기
    run: 1,     # 가동
    down: 2,    # 고장
    pm: 3       # 예방보전
  }

  # Associations
  belongs_to :manufacturing_process
  has_many :production_results, dependent: :restrict_with_error

  # Validations
  validates :equipment_code, presence: true, uniqueness: true
  validates :equipment_name, presence: true

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[equipment_code equipment_name status manufacturing_process_id location is_active created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[manufacturing_process production_results]
  end

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # 설비 상태 한글명 반환
  def status_i18n
    {
      "idle" => "대기",
      "run" => "가동",
      "down" => "고장",
      "pm" => "예방정비"
    }[status] || status
  end
end
