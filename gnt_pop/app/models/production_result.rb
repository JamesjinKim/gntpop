# 생산 실적 모델
# LOT별 생산 수량, 불량 수량, 작업 시간 등을 관리
class ProductionResult < ApplicationRecord
  # Associations
  belongs_to :tenant
  belongs_to :work_order
  belongs_to :manufacturing_process
  belongs_to :equipment, optional: true
  belongs_to :worker, optional: true
  has_many :defect_records, dependent: :destroy
  has_many :lot_sensor_snapshots, dependent: :destroy

  # Validations
  validates :lot_no, presence: true, uniqueness: true
  validates :good_qty, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :defect_qty, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[lot_no good_qty defect_qty work_order_id manufacturing_process_id equipment_id worker_id tenant_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[work_order manufacturing_process equipment worker defect_records lot_sensor_snapshots tenant]
  end

  # Callbacks
  before_validation :assign_current_tenant, on: :create
  after_create :capture_sensor_snapshot

  # Scopes
  scope :by_date, ->(date) { where(created_at: date.all_day) if date.present? }
  scope :by_period, ->(from, to) { where(created_at: from..to) if from.present? && to.present? }
  scope :recent, -> { order(created_at: :desc) }
  # 멀티테넌시 격리 — 명시적 호출 필수
  scope :for_tenant, ->(t) { where(tenant: t) }

  # 비즈니스 메서드

  # 총 생산 수량
  def total_qty
    good_qty + defect_qty
  end

  # 불량률 계산
  def defect_rate
    return 0 if total_qty.zero?
    (defect_qty.to_f / total_qty * 100).round(2)
  end

  private

  def assign_current_tenant
    # work_order 지정 시 그 테넌트 우선, 없으면 Current.tenant
    self.tenant_id ||= work_order&.tenant_id || Current.tenant&.id
  end

  # LOT 생성 시 센서 스냅샷 자동 캡처
  def capture_sensor_snapshot
    LotSensorSnapshotService.capture!(self, snapshot_type: "start")
  end
end
