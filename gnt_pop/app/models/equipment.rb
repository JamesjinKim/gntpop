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
  belongs_to :tenant
  belongs_to :manufacturing_process
  has_many :production_results, dependent: :restrict_with_error

  # Callbacks — 생성 시 Current.tenant 자동 할당
  before_validation :assign_current_tenant, on: :create

  # Validations
  validates :equipment_code, presence: true, uniqueness: true
  validates :equipment_name, presence: true

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[equipment_code equipment_name status manufacturing_process_id location is_active tenant_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[manufacturing_process production_results tenant]
  end

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  # 멀티테넌시 격리 — 명시적 호출 필수
  scope :for_tenant, ->(t) { where(tenant: t) }

  # 센서 데이터 기반 설비 상태 추론 (Layer 1 연계 준비)
  def update_status_from_sensor(sensor_data)
    new_status = EquipmentStatusInferenceService.infer(sensor_data)
    update!(status: new_status) if status != new_status.to_s
  end

  # 설비 상태 한글명 반환
  def status_i18n
    {
      "idle" => "대기",
      "run" => "가동",
      "down" => "고장",
      "pm" => "예방정비"
    }[status] || status
  end

  private

  def assign_current_tenant
    self.tenant_id ||= Current.tenant&.id
  end
end
