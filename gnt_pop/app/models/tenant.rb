# 테넌트 (다중임대 분리 단위)
# Factory Box Track 1 — 멀티테넌시 Level 1 (tenant_id 컬럼 스코핑)
# GnT는 내부 레퍼런스 테넌트 #1 (code: "gnt")
class Tenant < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error
  has_many :manufacturing_processes, dependent: :restrict_with_error
  has_many :equipments, dependent: :restrict_with_error
  has_many :workers, dependent: :restrict_with_error
  has_many :work_orders, dependent: :restrict_with_error
  has_many :production_results, dependent: :restrict_with_error
  has_many :defect_records, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_-]+\z/, message: "영소문자/숫자/하이픈/언더바만 허용" }
  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
