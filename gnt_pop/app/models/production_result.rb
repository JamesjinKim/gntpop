# 생산 실적 모델
# LOT별 생산 수량, 불량 수량, 작업 시간 등을 관리
class ProductionResult < ApplicationRecord
  # Associations
  belongs_to :work_order
  belongs_to :manufacturing_process
  belongs_to :equipment, optional: true
  belongs_to :worker, optional: true
  has_many :defect_records, dependent: :destroy

  # Validations
  validates :lot_no, presence: true, uniqueness: true
  validates :good_qty, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :defect_qty, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[lot_no good_qty defect_qty work_order_id manufacturing_process_id equipment_id worker_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[work_order manufacturing_process equipment worker defect_records]
  end

  # Scopes
  scope :by_date, ->(date) { where(created_at: date.all_day) if date.present? }
  scope :by_period, ->(from, to) { where(created_at: from..to) if from.present? && to.present? }
  scope :recent, -> { order(created_at: :desc) }

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
end
