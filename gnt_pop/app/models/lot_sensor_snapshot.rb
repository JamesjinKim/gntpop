class LotSensorSnapshot < ApplicationRecord
  belongs_to :production_result

  validates :lot_no, presence: true
  validates :snapshot_type, inclusion: { in: %w[start end periodic] }

  scope :by_lot, ->(lot_no) { where(lot_no: lot_no) }
  scope :starts, -> { where(snapshot_type: "start") }
  scope :ends, -> { where(snapshot_type: "end") }
end
