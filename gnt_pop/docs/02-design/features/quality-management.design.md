# 품질관리 (Quality Management) Design Document

> **요약**: 검사결과/불량분석/SPC 3개 화면의 기술 설계서
>
> **프로젝트**: GnT POP (생산시점관리 시스템)
> **버전**: 0.1.0
> **작성자**: GnT Dev Team
> **작성일**: 2026-02-12
> **상태**: Draft
> **Plan 문서**: [quality-management.plan.md](../../01-plan/features/quality-management.plan.md)

---

## 1. 개요

### 1.1 설계 목표

- 품질관리 전용 `quality/` 네임스페이스로 3개 컨트롤러 구현
- Chartkick + groupdate를 활용한 시각적 불량분석 대시보드
- SPC 계산 로직을 Service Object로 분리 (SRP)
- 기존 production_results, defect_records 데이터를 최대한 활용

### 1.2 설계 원칙

- **SRP**: 검사결과 CRUD, 불량분석, SPC를 각각 독립 컨트롤러로 분리
- **DRY**: 기존 모델(DefectRecord, ProductionResult) 재사용
- **Fat Model, Skinny Controller**: 집계 쿼리와 SPC 계산을 Service Object로 분리
- **Rails Convention**: RESTful 라우팅, namespace 구조

---

## 2. 아키텍처

### 2.1 컴포넌트 다이어그램

```
┌─────────────────────────────────────────────────────────┐
│                    Browser (Hotwire)                      │
│  검사결과 CRUD / 불량분석 차트 / SPC 관리도               │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────┴────────────────────────────────┐
│                  quality/ Namespace                       │
│                                                          │
│  ┌──────────────────┐  ┌──────────────────┐             │
│  │ InspectionsCtrl  │  │ DefectAnalysis   │             │
│  │ CRUD (index,     │  │ Controller       │             │
│  │  show, new,      │  │ (index)          │             │
│  │  edit, create,   │  │                  │             │
│  │  update, destroy)│  │  ┌────────────┐  │             │
│  │                  │  │  │ DefectAnaly│  │             │
│  │  ┌────────────┐  │  │  │ sisService │  │             │
│  │  │Inspection  │  │  │  └────────────┘  │             │
│  │  │Result model│  │  └──────────────────┘             │
│  │  │Inspection  │  │                                    │
│  │  │Item model  │  │  ┌──────────────────┐             │
│  │  └────────────┘  │  │ SpcController    │             │
│  └──────────────────┘  │ (index)          │             │
│                         │                  │             │
│                         │  ┌────────────┐  │             │
│                         │  │SpcCalcula- │  │             │
│                         │  │torService  │  │             │
│                         │  └────────────┘  │             │
│                         └──────────────────┘             │
└──────────────────────────────────────────────────────────┘
```

### 2.2 데이터 흐름

```
[검사결과 입력]
  사용자 → 검사결과 폼 (LOT 번호, 검사유형, 항목별 측정값)
       → InspectionsController#create
       → InspectionResult + InspectionItem 레코드 생성

[불량분석]
  사용자 → 기간 선택 → DefectAnalysisController#index
       → DefectAnalysisService 호출
       → 기존 defect_records + production_results 데이터 집계
       → Chartkick 차트 렌더링

[SPC]
  사용자 → 검사항목/기간 선택 → SpcController#index
       → SpcCalculatorService 호출
       → inspection_items 데이터로 X-bar, R, Cp, Cpk 계산
       → Chartkick 관리도 렌더링
```

---

## 3. 데이터 모델 설계

### 3.1 마이그레이션 - inspection_results

```ruby
# db/migrate/XXXXXXXX_create_inspection_results.rb
class CreateInspectionResults < ActiveRecord::Migration[8.1]
  def change
    create_table :inspection_results do |t|
      t.string :lot_no, null: false
      t.integer :insp_type, null: false        # enum: incoming(0), process(1), outgoing(2)
      t.date :insp_date, null: false
      t.references :worker, foreign_key: true  # 검사자
      t.references :manufacturing_process, foreign_key: true
      t.integer :result, default: 0            # enum: pass(0), fail(1), conditional(2)
      t.text :notes

      t.timestamps
    end

    add_index :inspection_results, :lot_no
    add_index :inspection_results, :insp_type
    add_index :inspection_results, :insp_date
  end
end
```

### 3.2 마이그레이션 - inspection_items

```ruby
# db/migrate/XXXXXXXX_create_inspection_items.rb
class CreateInspectionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inspection_items do |t|
      t.references :inspection_result, null: false, foreign_key: true
      t.string :item_name, null: false        # 예: "입력전압", "절연저항"
      t.string :spec_value                     # 예: "DC 450~850V", "≥ 100MΩ"
      t.decimal :measured_value, precision: 15, scale: 5  # 실측값
      t.string :unit                           # 예: "V", "MΩ", "μH"
      t.integer :judgment, default: 0          # enum: pass(0), fail(1)

      t.timestamps
    end
  end
end
```

### 3.3 모델 - InspectionResult

```ruby
# app/models/inspection_result.rb
class InspectionResult < ApplicationRecord
  # Associations
  belongs_to :worker, optional: true
  belongs_to :manufacturing_process, optional: true
  has_many :inspection_items, dependent: :destroy
  accepts_nested_attributes_for :inspection_items, reject_if: :all_blank

  # Enums
  enum :insp_type, { incoming: 0, process: 1, outgoing: 2 }
  enum :result, { pass: 0, fail: 1, conditional: 2 }, prefix: :result

  # Validations
  validates :lot_no, presence: true
  validates :insp_type, presence: true
  validates :insp_date, presence: true

  # Scopes
  scope :recent, -> { order(insp_date: :desc, created_at: :desc) }
  scope :by_period, ->(from, to) { where(insp_date: from..to) if from.present? && to.present? }

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[lot_no insp_type insp_date result worker_id manufacturing_process_id created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[worker manufacturing_process inspection_items]
  end
end
```

### 3.4 모델 - InspectionItem

```ruby
# app/models/inspection_item.rb
class InspectionItem < ApplicationRecord
  belongs_to :inspection_result

  enum :judgment, { pass: 0, fail: 1 }, prefix: :judgment

  validates :item_name, presence: true
end
```

---

## 4. 라우팅 설계

### 4.1 라우트 구조

```ruby
# config/routes.rb (추가분)
namespace :quality do
  resources :inspections              # 검사결과 CRUD
  get "defect_analysis", to: "defect_analysis#index"  # 불량분석
  get "spc", to: "spc#index"                          # SPC
end
```

### 4.2 URL 패턴

| Method | URL | Controller#Action | 설명 |
|--------|-----|-------------------|------|
| GET | /quality/inspections | inspections#index | 검사결과 목록 |
| GET | /quality/inspections/new | inspections#new | 검사결과 입력 폼 |
| POST | /quality/inspections | inspections#create | 검사결과 등록 |
| GET | /quality/inspections/:id | inspections#show | 검사결과 상세 |
| GET | /quality/inspections/:id/edit | inspections#edit | 검사결과 수정 폼 |
| PATCH | /quality/inspections/:id | inspections#update | 검사결과 수정 |
| DELETE | /quality/inspections/:id | inspections#destroy | 검사결과 삭제 |
| GET | /quality/defect_analysis | defect_analysis#index | 불량분석 대시보드 |
| GET | /quality/spc | spc#index | SPC 관리도 |

---

## 5. 컨트롤러 설계

### 5.1 Quality::InspectionsController

```ruby
# app/controllers/quality/inspections_controller.rb
class Quality::InspectionsController < ApplicationController
  before_action :set_inspection, only: [:show, :edit, :update, :destroy]

  def index
    @q = InspectionResult.includes(:worker, :manufacturing_process)
                         .ransack(params[:q])
    @pagy, @inspections = pagy(@q.result.recent)
  end

  def show
    @inspection_items = @inspection.inspection_items.order(:id)
  end

  def new
    @inspection = InspectionResult.new(insp_date: Date.current)
    3.times { @inspection.inspection_items.build }
    load_form_data
  end

  def create
    @inspection = InspectionResult.new(inspection_params)

    if @inspection.save
      redirect_to quality_inspections_path,
        notice: "검사결과가 등록되었습니다."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    if @inspection.update(inspection_params)
      redirect_to quality_inspections_path, notice: "검사결과가 수정되었습니다."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @inspection.destroy!
    redirect_to quality_inspections_path, notice: "검사결과가 삭제되었습니다."
  end

  private

  def set_inspection
    @inspection = InspectionResult.find(params[:id])
  end

  def inspection_params
    params.require(:inspection_result).permit(
      :lot_no, :insp_type, :insp_date, :worker_id,
      :manufacturing_process_id, :result, :notes,
      inspection_items_attributes: [:id, :item_name, :spec_value,
                                     :measured_value, :unit, :judgment, :_destroy]
    )
  end

  def load_form_data
    @workers = Worker.active.order(:name)
    @processes = ManufacturingProcess.active.ordered
  end
end
```

### 5.2 Quality::DefectAnalysisController

```ruby
# app/controllers/quality/defect_analysis_controller.rb
class Quality::DefectAnalysisController < ApplicationController
  def index
    @from = params[:from].present? ? Date.parse(params[:from]) : 30.days.ago.to_date
    @to = params[:to].present? ? Date.parse(params[:to]) : Date.current

    service = DefectAnalysisService.new(@from, @to)
    @summary = service.summary
    @pareto_data = service.pareto_by_defect_code
    @by_process = service.defect_rate_by_process
    @by_product = service.defect_rate_by_product
    @daily_trend = service.daily_defect_trend
  end
end
```

### 5.3 Quality::SpcController

```ruby
# app/controllers/quality/spc_controller.rb
class Quality::SpcController < ApplicationController
  def index
    @item_name = params[:item_name] || default_item_name
    @from = params[:from].present? ? Date.parse(params[:from]) : 30.days.ago.to_date
    @to = params[:to].present? ? Date.parse(params[:to]) : Date.current

    service = SpcCalculatorService.new(@item_name, @from, @to)
    @xbar_data = service.xbar_chart_data
    @r_data = service.r_chart_data
    @control_limits = service.control_limits
    @capability = service.process_capability
    @item_names = InspectionItem.distinct.pluck(:item_name)
  end

  private

  def default_item_name
    InspectionItem.distinct.pluck(:item_name).first || "입력전압"
  end
end
```

---

## 6. 서비스 설계

### 6.1 DefectAnalysisService

```ruby
# app/services/defect_analysis_service.rb
class DefectAnalysisService
  def initialize(from, to)
    @from = from
    @to = to
    @results = ProductionResult.where(created_at: @from.beginning_of_day..@to.end_of_day)
  end

  # 요약 통계 (총 생산, 총 불량, 불량률)
  def summary
    total_good = @results.sum(:good_qty)
    total_defect = @results.sum(:defect_qty)
    total = total_good + total_defect
    {
      total_production: total,
      total_good: total_good,
      total_defect: total_defect,
      defect_rate: total.positive? ? (total_defect.to_f / total * 100).round(2) : 0
    }
  end

  # 불량유형별 파레토 데이터
  def pareto_by_defect_code
    DefectRecord
      .joins(:production_result, :defect_code)
      .where(production_results: { created_at: @from.beginning_of_day..@to.end_of_day })
      .group("defect_codes.name")
      .order("sum_defect_qty DESC")
      .sum(:defect_qty)
  end

  # 공정별 불량률
  def defect_rate_by_process
    @results
      .joins(:manufacturing_process)
      .group("manufacturing_processes.process_name")
      .select(
        "manufacturing_processes.process_name as name",
        "SUM(defect_qty) * 100.0 / NULLIF(SUM(good_qty + defect_qty), 0) as rate"
      )
      .map { |r| [r.name, r.rate&.round(2) || 0] }
      .to_h
  end

  # 제품별 불량률
  def defect_rate_by_product
    @results
      .joins(work_order: :product)
      .group("products.product_name")
      .select(
        "products.product_name as name",
        "SUM(defect_qty) * 100.0 / NULLIF(SUM(good_qty + defect_qty), 0) as rate"
      )
      .map { |r| [r.name, r.rate&.round(2) || 0] }
      .to_h
  end

  # 일별 불량률 추이
  def daily_defect_trend
    @results
      .group_by_day(:created_at, range: @from..@to)
      .select(
        "SUM(defect_qty) * 100.0 / NULLIF(SUM(good_qty + defect_qty), 0) as rate"
      )
      .map { |date, result| [date, result.first&.rate&.round(2) || 0] }
      .to_h
  end
end
```

### 6.2 SpcCalculatorService

```ruby
# app/services/spc_calculator_service.rb
class SpcCalculatorService
  # X-bar R 관리도 상수 (서브그룹 크기 n=5 기준)
  A2 = 0.577
  D3 = 0.0
  D4 = 2.114

  def initialize(item_name, from, to, subgroup_size: 5)
    @item_name = item_name
    @from = from
    @to = to
    @subgroup_size = subgroup_size
    @items = InspectionItem
      .joins(:inspection_result)
      .where(item_name: item_name)
      .where(inspection_results: { insp_date: from..to })
      .order("inspection_results.insp_date")
  end

  # X-bar 관리도 데이터 (서브그룹별 평균)
  def xbar_chart_data
    subgroups.map { |date, values| [date, mean(values)] }
  end

  # R 관리도 데이터 (서브그룹별 범위)
  def r_chart_data
    subgroups.map { |date, values| [date, values.max - values.min] }
  end

  # 관리 한계선
  def control_limits
    xbar_values = subgroups.map { |_, v| mean(v) }
    r_values = subgroups.map { |_, v| v.max - v.min }

    x_double_bar = mean(xbar_values)
    r_bar = mean(r_values)

    {
      xbar: {
        ucl: (x_double_bar + A2 * r_bar).round(4),
        cl: x_double_bar.round(4),
        lcl: (x_double_bar - A2 * r_bar).round(4)
      },
      r: {
        ucl: (D4 * r_bar).round(4),
        cl: r_bar.round(4),
        lcl: (D3 * r_bar).round(4)
      }
    }
  end

  # 공정능력지수
  def process_capability
    all_values = @items.pluck(:measured_value).compact.map(&:to_f)
    return { cp: nil, cpk: nil, data_count: 0 } if all_values.size < 2

    sigma = std_dev(all_values)
    return { cp: nil, cpk: nil, data_count: all_values.size } if sigma.zero?

    # 규격 한계는 inspection_items의 spec_value에서 파싱하거나
    # 평균 ± 3sigma를 기본값으로 사용
    avg = mean(all_values)
    usl = avg + 3 * sigma
    lsl = avg - 3 * sigma

    cp = ((usl - lsl) / (6 * sigma)).round(3)
    cpu = ((usl - avg) / (3 * sigma)).round(3)
    cpl = ((avg - lsl) / (3 * sigma)).round(3)
    cpk = [cpu, cpl].min.round(3)

    { cp: cp, cpk: cpk, data_count: all_values.size }
  end

  private

  def subgroups
    @subgroups ||= begin
      values = @items.pluck("inspection_results.insp_date", :measured_value)
      values.group_by(&:first)
            .transform_values { |pairs| pairs.map { |_, v| v.to_f } }
            .select { |_, v| v.size >= 2 }
    end
  end

  def mean(arr)
    return 0.0 if arr.empty?
    arr.sum.to_f / arr.size
  end

  def std_dev(arr)
    return 0.0 if arr.size < 2
    avg = mean(arr)
    Math.sqrt(arr.sum { |v| (v - avg)**2 } / (arr.size - 1))
  end
end
```

---

## 7. UI/UX 설계

### 7.1 화면 목록

| 화면 | URL | 설명 |
|------|-----|------|
| 검사결과 목록 | /quality/inspections | 필터 + 테이블 (Ransack) |
| 검사결과 입력 | /quality/inspections/new | 폼 (nested items) |
| 검사결과 상세 | /quality/inspections/:id | 항목별 판정 결과 |
| 검사결과 수정 | /quality/inspections/:id/edit | 폼 (기존 데이터) |
| 불량분석 | /quality/defect_analysis | 기간 필터 + 차트 4종 |
| SPC | /quality/spc | 항목/기간 필터 + 관리도 2종 + Cp/Cpk |

### 7.2 검사결과 목록 (inspections/index)

```
┌──────────────────────────────────────────────────────┐
│  검사결과 관리                         [검사결과 입력]  │
├──────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────┐  │
│  │ LOT번호 [        ] 검사유형 [전체 v] 판정 [v]  │  │
│  │                                    [검색]      │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │ LOT번호      │유형  │검사일 │판정│검사자│관리  │  │
│  │ L-202602..   │공정  │02-12 │합격│이영희│수정삭제│  │
│  │ L-202602..   │출하  │02-12 │불합격│...│수정삭제│  │
│  └────────────────────────────────────────────────┘  │
│  << 1 2 3 >>                                         │
└──────────────────────────────────────────────────────┘
```

### 7.3 검사결과 입력 (inspections/new)

```
┌──────────────────────────────────────────────────────┐
│  검사결과 입력                                        │
├──────────────────────────────────────────────────────┤
│  LOT 번호   [                        ]               │
│  검사유형   [수입검사 v]   검사일 [2026-02-12]        │
│  공정       [선택 v]       검사자 [선택 v]            │
│  판정       [합격 v]                                  │
│                                                      │
│  ─── 검사항목 ───────────────────────────────────     │
│  │ 항목명    │ 규격      │ 측정값  │ 단위 │ 판정 │    │
│  │ 입력전압  │ 450~850V  │ 620.5  │ V   │ 합격 │    │
│  │ 출력전압  │ 12±0.5V   │ 12.1   │ V   │ 합격 │    │
│  │ 절연저항  │ ≥100MΩ    │ 350    │ MΩ  │ 합격 │    │
│                                                      │
│  비고   [                                    ]        │
│                                                      │
│                            [취소]  [등록]              │
└──────────────────────────────────────────────────────┘
```

### 7.4 불량분석 대시보드 (defect_analysis/index)

```
┌──────────────────────────────────────────────────────┐
│  불량분석                                             │
├──────────────────────────────────────────────────────┤
│  기간: [2026-01-13] ~ [2026-02-12]        [조회]     │
│                                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐  │
│  │총생산수량│ │총불량수량│ │  불량률   │ │검사건수│  │
│  │ 12,500  │ │   342   │ │  2.74%  │ │   89  │  │
│  └──────────┘ └──────────┘ └──────────┘ └────────┘  │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │        불량유형별 파레토 차트                   │    │
│  │  ████████████████  크랙 (42%)                 │    │
│  │  ██████████       외관불량 (28%)               │    │
│  │  █████           납볼 (15%)                   │    │
│  │  ███            기타 (15%)                    │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  ┌──────────────────────┐ ┌──────────────────────┐   │
│  │  공정별 불량률        │ │  제품별 불량률        │   │
│  │  (막대 차트)          │ │  (막대 차트)          │   │
│  └──────────────────────┘ └──────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │        일별 불량률 추이 (꺾은선 차트)           │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

### 7.5 SPC 관리도 (spc/index)

```
┌──────────────────────────────────────────────────────┐
│  SPC 통계적 공정관리                                   │
├──────────────────────────────────────────────────────┤
│  검사항목: [입력전압 v]                                │
│  기간: [2026-01-13] ~ [2026-02-12]        [조회]     │
│                                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐             │
│  │   Cp     │ │   Cpk    │ │ 데이터수  │             │
│  │  1.33   │ │  1.21   │ │   150   │             │
│  └──────────┘ └──────────┘ └──────────┘             │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │        X-bar 관리도                            │    │
│  │  UCL ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ (650.2)  │    │
│  │  ─────●──●───●──●──●───●──●──●──── (620.5)  │    │
│  │  LCL ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ (590.8)  │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │        R 관리도                                │    │
│  │  UCL ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ (42.3)   │    │
│  │  ─────●──●───●──●──●───●──●──●──── (20.1)   │    │
│  │  LCL ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ (0.0)    │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

---

## 8. 에러 처리

| 상황 | 처리 | 사용자 표시 |
|------|------|------------|
| 검사 데이터 없음 (불량분석/SPC) | 빈 상태 메시지 | "해당 기간에 데이터가 없습니다" |
| SPC 데이터 부족 (2건 미만) | Cp/Cpk null 반환 | "데이터 부족 (최소 2건 필요)" |
| 검사결과 미발견 (show) | redirect_to index + alert | "검사결과를 찾을 수 없습니다" |
| 기간 파라미터 오류 | 기본값 적용 (최근 30일) | 기본 기간으로 조회 |
| 인증 미완료 | Authentication concern | 로그인 페이지로 리다이렉트 |

---

## 9. 보안 고려사항

- [x] Authentication concern 적용 (ApplicationController 상속)
- [x] Strong Parameters로 입력값 필터링
- [x] SQL Injection 방어 (ActiveRecord ORM 사용)
- [x] XSS 방어 (ERB 자동 이스케이프)

---

## 10. 구현 순서

### 10.1 파일 구조

```
app/
├── controllers/
│   └── quality/
│       ├── inspections_controller.rb       # (신규)
│       ├── defect_analysis_controller.rb   # (신규)
│       └── spc_controller.rb              # (신규)
├── models/
│   ├── inspection_result.rb               # (신규)
│   └── inspection_item.rb                 # (신규)
├── services/
│   ├── defect_analysis_service.rb         # (신규)
│   └── spc_calculator_service.rb          # (신규)
├── views/
│   └── quality/
│       ├── inspections/
│       │   ├── index.html.erb             # (신규) 목록
│       │   ├── show.html.erb              # (신규) 상세
│       │   ├── new.html.erb               # (신규) 입력
│       │   ├── edit.html.erb              # (신규) 수정
│       │   └── _form.html.erb             # (신규) 폼 파셜
│       ├── defect_analysis/
│       │   └── index.html.erb             # (신규) 대시보드
│       └── spc/
│           └── index.html.erb             # (신규) 관리도
├── config/
│   └── routes.rb                          # (수정) quality 네임스페이스
└── views/layouts/
    └── _sidebar.html.erb                  # (수정) 메뉴 링크 연결
```

### 10.2 구현 순서 (의존성 기반)

| 단계 | 작업 | 파일 | 의존성 |
|------|------|------|--------|
| **Step 1** | DB 마이그레이션 | db/migrate/xxx_create_inspection_results.rb, xxx_create_inspection_items.rb | 없음 |
| **Step 2** | 모델 생성 | app/models/inspection_result.rb, inspection_item.rb | Step 1 |
| **Step 3** | 라우트 추가 | config/routes.rb | 없음 |
| **Step 4** | 검사결과 컨트롤러 | app/controllers/quality/inspections_controller.rb | Step 2, 3 |
| **Step 5** | 검사결과 뷰 5개 | app/views/quality/inspections/*.html.erb | Step 4 |
| **Step 6** | DefectAnalysisService | app/services/defect_analysis_service.rb | 없음 |
| **Step 7** | 불량분석 컨트롤러 + 뷰 | app/controllers/quality/defect_analysis_controller.rb, views/ | Step 3, 6 |
| **Step 8** | SpcCalculatorService | app/services/spc_calculator_service.rb | Step 2 |
| **Step 9** | SPC 컨트롤러 + 뷰 | app/controllers/quality/spc_controller.rb, views/ | Step 3, 8 |
| **Step 10** | 사이드바 링크 연결 | app/views/layouts/_sidebar.html.erb | Step 3 |
| **Step 11** | 시드 데이터 | db/seeds.rb | Step 2 |

---

## 버전 이력

| 버전 | 날짜 | 변경 사항 | 작성자 |
|------|------|----------|--------|
| 0.1 | 2026-02-12 | 초안 작성 | GnT Dev Team |
