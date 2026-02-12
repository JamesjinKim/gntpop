class InspectionResult < ApplicationRecord
  belongs_to :worker, optional: true
  belongs_to :manufacturing_process, optional: true
  has_many :inspection_items, dependent: :destroy
  accepts_nested_attributes_for :inspection_items, reject_if: :all_blank, allow_destroy: true

  enum :insp_type, { incoming: 0, process: 1, outgoing: 2 }
  enum :result, { pass: 0, fail: 1, conditional: 2 }, prefix: :result

  validates :lot_no, presence: true
  validates :insp_type, presence: true
  validates :insp_date, presence: true

  scope :recent, -> { order(insp_date: :desc, created_at: :desc) }
  scope :by_period, ->(from, to) { where(insp_date: from..to) if from.present? && to.present? }

  def self.ransackable_attributes(auth_object = nil)
    %w[lot_no insp_type insp_date result worker_id manufacturing_process_id created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[worker manufacturing_process inspection_items]
  end

  def insp_type_label
    { "incoming" => "수입검사", "process" => "공정검사", "outgoing" => "출하검사" }[insp_type]
  end

  def result_label
    { "pass" => "합격", "fail" => "불합격", "conditional" => "조건부합격" }[result]
  end
end
