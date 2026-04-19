class InspectionItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :inspection_result

  enum :judgment, { pass: 0, fail: 1 }, prefix: :judgment

  # Callbacks — parent(InspectionResult)의 tenant 상속
  before_validation :assign_tenant_from_parent, on: :create

  validates :item_name, presence: true

  # Scopes
  scope :for_tenant, ->(t) { where(tenant: t) }

  def judgment_label
    { "pass" => "합격", "fail" => "불합격" }[judgment]
  end

  private

  def assign_tenant_from_parent
    self.tenant_id ||= inspection_result&.tenant_id || Current.tenant&.id
  end
end
