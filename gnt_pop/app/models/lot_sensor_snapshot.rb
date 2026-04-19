class LotSensorSnapshot < ApplicationRecord
  belongs_to :tenant
  belongs_to :production_result

  # Callbacks — parent(ProductionResult)의 tenant 상속
  before_validation :assign_tenant_from_parent, on: :create

  validates :lot_no, presence: true
  validates :snapshot_type, inclusion: { in: %w[start end periodic] }

  scope :by_lot, ->(lot_no) { where(lot_no: lot_no) }
  scope :starts, -> { where(snapshot_type: "start") }
  scope :ends, -> { where(snapshot_type: "end") }
  scope :for_tenant, ->(t) { where(tenant: t) }

  private

  def assign_tenant_from_parent
    self.tenant_id ||= production_result&.tenant_id || Current.tenant&.id
  end
end
