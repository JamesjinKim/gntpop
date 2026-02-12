# 작업 지시 모델
# 제품별 생산 계획과 진행 상태를 관리
class WorkOrder < ApplicationRecord
  # Enums
  enum :status, {
    planned: 0,      # 계획
    in_progress: 1,  # 진행중
    completed: 2,    # 완료
    cancelled: 3     # 취소
  }

  # Associations
  belongs_to :product
  has_many :production_results, dependent: :restrict_with_error

  # Validations
  validates :work_order_code, presence: true, uniqueness: true
  validates :order_qty, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :plan_date, presence: true

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[work_order_code status plan_date order_qty priority product_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[product production_results]
  end

  # Scopes
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_date, ->(date) { where(plan_date: date) if date.present? }
  scope :recent, -> { order(created_at: :desc) }

  # 비즈니스 메서드

  # 총 양품 수량
  def total_good_qty
    production_results.sum(:good_qty)
  end

  # 총 불량 수량
  def total_defect_qty
    production_results.sum(:defect_qty)
  end

  # 진행률 계산
  def progress_rate
    return 0 if order_qty.zero?
    (total_good_qty.to_f / order_qty * 100).round(1)
  end
end
