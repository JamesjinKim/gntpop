class InspectionItem < ApplicationRecord
  belongs_to :inspection_result

  enum :judgment, { pass: 0, fail: 1 }, prefix: :judgment

  validates :item_name, presence: true

  def judgment_label
    { "pass" => "합격", "fail" => "불합격" }[judgment]
  end
end
