# 생산실적 관리 (Production Tracking) Design Document

> **요약**: LOT 기반 생산실적 등록/조회/통계 기능의 기술 설계서
>
> **프로젝트**: GnT POP (생산시점관리 시스템)
> **버전**: 0.2.0
> **작성자**: GnT Dev Team
> **작성일**: 2026-02-11
> **상태**: Draft
> **Plan 문서**: [production-tracking.plan.md](../01-plan/features/production-tracking.plan.md)

---

## 1. 개요

### 1.1 설계 목표

- 기준정보(제품/공정/설비/작업자/불량코드)를 관리하는 CRUD 시스템 구현
- 작업지시 → 생산실적 입력 → LOT 추적의 핵심 생산 흐름 구현
- 대시보드의 목업 데이터를 실제 DB 데이터로 전환
- Clean Code 원칙에 따른 Service Object 패턴 적용

### 1.2 설계 원칙

- **SRP (Single Responsibility)**: 컨트롤러는 요청/응답만, 비즈니스 로직은 Service Object에 위임
- **Rails Convention**: RESTful 라우팅, 네임스페이스 컨트롤러, 표준 CRUD 패턴
- **DRY**: 공통 UI 컴포넌트(폼, 테이블, 검색)를 partial로 재사용
- **Fat Model, Skinny Controller**: 유효성 검증과 스코프는 모델에 정의

---

## 2. 아키텍처

### 2.1 컴포넌트 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                        Browser (Hotwire)                         │
│  Turbo Drive + Turbo Frames + Stimulus Controllers               │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP (Turbo Frame requests)
┌────────────────────────────┴────────────────────────────────────┐
│                     Rails 8 Application                          │
│                                                                  │
│  ┌──────────────┐  ┌──────────────────┐  ┌───────────────────┐  │
│  │ Controllers   │  │   Services       │  │   Models          │  │
│  │ (Namespace)   │──│ (Business Logic) │──│ (ActiveRecord)    │  │
│  │               │  │                  │  │                   │  │
│  │ Masters::     │  │ LotGenerator     │  │ Product           │  │
│  │ Productions:: │  │ WOCodeGenerator  │  │ ManufProcess      │  │
│  │ Dashboard     │  │ DashboardQuery   │  │ Equipment         │  │
│  └──────────────┘  └──────────────────┘  │ Worker            │  │
│                                           │ WorkOrder         │  │
│  ┌──────────────┐                        │ ProductionResult  │  │
│  │ Views (ERB)   │                        │ DefectCode        │  │
│  │ + Partials    │                        │ DefectRecord      │  │
│  │ + Turbo       │                        └───────────────────┘  │
│  └──────────────┘                                │               │
└──────────────────────────────────────────────────┼───────────────┘
                                                   │
┌──────────────────────────────────────────────────┴───────────────┐
│                         SQLite3 Database                          │
│  products | manufacturing_processes | equipments | workers        │
│  work_orders | production_results | defect_codes | defect_records │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 데이터 흐름

```
[작업지시 등록]
  사용자 → WorkOrdersController#create → WorkOrder.create
         → WorkOrderCodeGeneratorService (코드 자동생성)

[생산실적 입력]
  사용자 → ProductionResultsController#create → ProductionResult.create
         → LotGeneratorService (LOT 번호 자동생성)
         → DefectRecord.create (불량 시)

[대시보드 조회]
  사용자 → DashboardController#index → DashboardQueryService
         → ProductionResult 집계 쿼리 → KPI 계산
```

### 2.3 의존성

| 컴포넌트 | 의존 대상 | 용도 |
|----------|----------|------|
| Masters 컨트롤러 | Ransack, Pagy | 검색, 페이지네이션 |
| Productions 컨트롤러 | Service Objects | 코드/LOT 생성 |
| DashboardController | DashboardQueryService | KPI 집계 쿼리 |
| Views | Tailwind CSS, Turbo Frames | UI 렌더링 |

---

## 3. 데이터 모델

### 3.1 엔티티 정의

#### Product (제품 마스터)

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  enum :product_group, {
    converter: 0,
    transformer_inductor: 1,
    electronic_component: 2,
    circuit_board: 3
  }

  has_many :work_orders, dependent: :restrict_with_error

  validates :product_code, presence: true, uniqueness: true
  validates :product_name, presence: true
  validates :product_group, presence: true

  scope :active, -> { where(is_active: true) }
  scope :by_group, ->(group) { where(product_group: group) if group.present? }
end
```

#### ManufacturingProcess (공정 마스터)

```ruby
# app/models/manufacturing_process.rb
class ManufacturingProcess < ApplicationRecord
  has_many :equipments, dependent: :restrict_with_error
  has_many :workers, dependent: :nullify
  has_many :production_results, dependent: :restrict_with_error

  validates :process_code, presence: true, uniqueness: true
  validates :process_name, presence: true
  validates :process_order, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:process_order) }
end
```

#### Equipment (설비 마스터)

```ruby
# app/models/equipment.rb
class Equipment < ApplicationRecord
  enum :status, { idle: 0, run: 1, down: 2, pm: 3 }

  belongs_to :manufacturing_process
  has_many :production_results, dependent: :restrict_with_error

  validates :equipment_code, presence: true, uniqueness: true
  validates :equipment_name, presence: true

  scope :active, -> { where(is_active: true) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
end
```

#### Worker (작업자 마스터)

```ruby
# app/models/worker.rb
class Worker < ApplicationRecord
  belongs_to :manufacturing_process, optional: true
  has_many :production_results, dependent: :restrict_with_error

  validates :employee_number, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
end
```

#### DefectCode (불량코드 마스터)

```ruby
# app/models/defect_code.rb
class DefectCode < ApplicationRecord
  has_many :defect_records, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
end
```

#### WorkOrder (작업지시)

```ruby
# app/models/work_order.rb
class WorkOrder < ApplicationRecord
  enum :status, { planned: 0, in_progress: 1, completed: 2, cancelled: 3 }

  belongs_to :product
  has_many :production_results, dependent: :restrict_with_error

  validates :work_order_code, presence: true, uniqueness: true
  validates :order_qty, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :plan_date, presence: true

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_date, ->(date) { where(plan_date: date) if date.present? }
  scope :recent, -> { order(created_at: :desc) }

  def total_good_qty
    production_results.sum(:good_qty)
  end

  def total_defect_qty
    production_results.sum(:defect_qty)
  end

  def progress_rate
    return 0 if order_qty.zero?
    (total_good_qty.to_f / order_qty * 100).round(1)
  end
end
```

#### ProductionResult (생산실적)

```ruby
# app/models/production_result.rb
class ProductionResult < ApplicationRecord
  belongs_to :work_order
  belongs_to :manufacturing_process
  belongs_to :equipment, optional: true
  belongs_to :worker, optional: true
  has_many :defect_records, dependent: :destroy

  validates :lot_no, presence: true, uniqueness: true
  validates :good_qty, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :defect_qty, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :by_date, ->(date) { where(created_at: date.all_day) if date.present? }
  scope :by_period, ->(from, to) { where(created_at: from..to) if from.present? && to.present? }
  scope :recent, -> { order(created_at: :desc) }

  def total_qty
    good_qty + defect_qty
  end

  def defect_rate
    return 0 if total_qty.zero?
    (defect_qty.to_f / total_qty * 100).round(2)
  end
end
```

#### DefectRecord (불량기록)

```ruby
# app/models/defect_record.rb
class DefectRecord < ApplicationRecord
  belongs_to :production_result
  belongs_to :defect_code

  validates :defect_qty, numericality: { only_integer: true, greater_than: 0 }
end
```

### 3.2 엔티티 관계도 (ERD)

```
[Product] 1 ──── N [WorkOrder] 1 ──── N [ProductionResult]
                                              │
[ManufacturingProcess] 1 ──── N [Equipment]   │
         │                         │          │
         └─────────────────────────┴── N ─────┘
                                              │
[Worker] 1 ──────────────────────── N ────────┘
                                              │
[DefectCode] 1 ──── N [DefectRecord] N ───── 1┘
```

### 3.3 데이터베이스 마이그레이션

```ruby
# 마이그레이션 순서 (의존성 기준)
# 1. create_products
# 2. create_manufacturing_processes
# 3. create_equipments (→ manufacturing_processes FK)
# 4. create_workers (→ manufacturing_processes FK)
# 5. create_defect_codes
# 6. create_work_orders (→ products FK)
# 7. create_production_results (→ work_orders, manufacturing_processes, equipments, workers FK)
# 8. create_defect_records (→ production_results, defect_codes FK)
```

#### products 테이블

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| id | integer | PK | - |
| product_code | string | NOT NULL, UNIQUE | 'CVT-001' |
| product_name | string | NOT NULL | 제품명 |
| product_group | integer | NOT NULL | enum: converter=0, transformer_inductor=1, electronic_component=2, circuit_board=3 |
| spec | text | - | 사양 |
| unit | string | DEFAULT 'EA' | 단위 |
| is_active | boolean | DEFAULT true | 활성 여부 |

#### manufacturing_processes 테이블

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| id | integer | PK | - |
| process_code | string | NOT NULL, UNIQUE | 'P010' |
| process_name | string | NOT NULL | 공정명 |
| process_order | integer | NOT NULL | 공정 순서 |
| std_cycle_time | decimal(10,2) | - | 표준 사이클타임(초) |
| is_active | boolean | DEFAULT true | 활성 여부 |

#### equipments 테이블

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| id | integer | PK | - |
| equipment_code | string | NOT NULL, UNIQUE | 설비코드 |
| equipment_name | string | NOT NULL | 설비명 |
| manufacturing_process_id | integer | FK | 소속 공정 |
| location | string | - | 설치 위치 |
| status | integer | DEFAULT 0 | enum: idle=0, run=1, down=2, pm=3 |
| is_active | boolean | DEFAULT true | 활성 여부 |

#### workers 테이블

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| id | integer | PK | - |
| employee_number | string | NOT NULL, UNIQUE | 사원번호 |
| name | string | NOT NULL | 이름 |
| manufacturing_process_id | integer | FK (optional) | 담당 공정 |
| is_active | boolean | DEFAULT true | 활성 여부 |

#### defect_codes 테이블

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| id | integer | PK | - |
| code | string | NOT NULL, UNIQUE | 불량코드 |
| name | string | NOT NULL | 불량유형명 |
| description | text | - | 설명 |
| is_active | boolean | DEFAULT true | 활성 여부 |

#### work_orders 테이블

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| id | integer | PK | - |
| work_order_code | string | NOT NULL, UNIQUE | 'WO-20260211-001' |
| product_id | integer | FK, NOT NULL | 대상 제품 |
| order_qty | integer | NOT NULL | 지시 수량 |
| plan_date | date | NOT NULL | 계획일 |
| status | integer | DEFAULT 0 | enum: planned=0, in_progress=1, completed=2, cancelled=3 |
| priority | integer | DEFAULT 5 | 우선순위 (1=최우선, 10=낮음) |

**인덱스**: plan_date, status

#### production_results 테이블

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| id | integer | PK | - |
| work_order_id | integer | FK, NOT NULL | 작업지시 |
| manufacturing_process_id | integer | FK, NOT NULL | 공정 |
| equipment_id | integer | FK (optional) | 설비 |
| worker_id | integer | FK (optional) | 작업자 |
| lot_no | string | NOT NULL, UNIQUE | LOT 번호 |
| good_qty | integer | DEFAULT 0 | 양품 수량 |
| defect_qty | integer | DEFAULT 0 | 불량 수량 |
| start_time | datetime | - | 작업 시작 시간 |
| end_time | datetime | - | 작업 종료 시간 |

**인덱스**: lot_no, created_at

#### defect_records 테이블

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| id | integer | PK | - |
| production_result_id | integer | FK, NOT NULL | 생산실적 |
| defect_code_id | integer | FK, NOT NULL | 불량코드 |
| defect_qty | integer | DEFAULT 1 | 불량 수량 |
| description | text | - | 상세 설명 |

---

## 4. 라우팅 설계

### 4.1 라우트 구조

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # 기준정보 (Masters)
  namespace :masters do
    resources :products
    resources :manufacturing_processes
    resources :equipments
    resources :workers
    resources :defect_codes
  end

  # 생산관리 (Productions)
  namespace :productions do
    resources :work_orders do
      member do
        patch :start     # 작업 시작 (planned → in_progress)
        patch :complete  # 작업 완료 (in_progress → completed)
        patch :cancel    # 작업 취소
      end
    end
    resources :production_results
  end

  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboard#index"
end
```

### 4.2 URL 패턴

| Method | URL | Controller#Action | 설명 |
|--------|-----|-------------------|------|
| GET | /masters/products | masters/products#index | 제품 목록 |
| GET | /masters/products/new | masters/products#new | 제품 등록 폼 |
| POST | /masters/products | masters/products#create | 제품 등록 |
| GET | /masters/products/:id/edit | masters/products#edit | 제품 수정 폼 |
| PATCH | /masters/products/:id | masters/products#update | 제품 수정 |
| DELETE | /masters/products/:id | masters/products#destroy | 제품 삭제 |
| GET | /productions/work_orders | productions/work_orders#index | 작업지시 목록 |
| POST | /productions/work_orders | productions/work_orders#create | 작업지시 등록 |
| PATCH | /productions/work_orders/:id/start | productions/work_orders#start | 작업 시작 |
| PATCH | /productions/work_orders/:id/complete | productions/work_orders#complete | 작업 완료 |
| GET | /productions/production_results | productions/production_results#index | 생산실적 목록 |
| POST | /productions/production_results | productions/production_results#create | 생산실적 입력 |

---

## 5. Service Objects 설계

### 5.1 LotGeneratorService

```ruby
# app/services/lot_generator_service.rb
# LOT 번호 형식: L-YYYYMMDD-제품코드-NNN
# 예: L-20260211-CVT-001
class LotGeneratorService
  def initialize(work_order)
    @work_order = work_order
    @product = work_order.product
  end

  def call
    date_part = Date.current.strftime("%Y%m%d")
    product_part = @product.product_code
    sequence = next_sequence(date_part, product_part)
    "L-#{date_part}-#{product_part}-#{sequence}"
  end

  private

  def next_sequence(date_part, product_part)
    prefix = "L-#{date_part}-#{product_part}-"
    last = ProductionResult.where("lot_no LIKE ?", "#{prefix}%")
                           .order(:lot_no)
                           .last
    if last
      last_seq = last.lot_no.split("-").last.to_i
      format("%03d", last_seq + 1)
    else
      "001"
    end
  end
end
```

### 5.2 WorkOrderCodeGeneratorService

```ruby
# app/services/work_order_code_generator_service.rb
# 작업지시 코드 형식: WO-YYYYMMDD-NNN
# 예: WO-20260211-001
class WorkOrderCodeGeneratorService
  def call
    date_part = Date.current.strftime("%Y%m%d")
    sequence = next_sequence(date_part)
    "WO-#{date_part}-#{sequence}"
  end

  private

  def next_sequence(date_part)
    prefix = "WO-#{date_part}-"
    last = WorkOrder.where("work_order_code LIKE ?", "#{prefix}%")
                    .order(:work_order_code)
                    .last
    if last
      last_seq = last.work_order_code.split("-").last.to_i
      format("%03d", last_seq + 1)
    else
      "001"
    end
  end
end
```

### 5.3 DashboardQueryService

```ruby
# app/services/dashboard_query_service.rb
# 대시보드 KPI 집계 쿼리를 담당
class DashboardQueryService
  def initialize(date: Date.current)
    @date = date
  end

  def kpi_data
    {
      production: production_kpi,
      defect: defect_kpi,
      equipment: equipment_kpi,
      work_order: work_order_kpi
    }
  end

  def process_data
    ManufacturingProcess.active.ordered.map do |process|
      results = process.production_results.by_date(@date)
      target = daily_target(process)
      actual = results.sum(:good_qty)
      {
        name: process.process_name,
        progress: target.positive? ? (actual.to_f / target * 100).round(0) : 0,
        target: target,
        actual: actual,
        status: process_status(process)
      }
    end
  end

  def equipment_data
    Equipment.active.includes(:manufacturing_process).map do |eq|
      { name: eq.equipment_name, status: eq.status, time: equipment_time(eq) }
    end
  end

  def recent_results(limit: 5)
    ProductionResult.includes(:work_order, :manufacturing_process)
                    .recent
                    .limit(limit)
  end

  private

  def production_kpi
    today_results = ProductionResult.by_date(@date)
    actual = today_results.sum(:good_qty)
    target = daily_production_target
    { actual: actual, target: target, rate: target.positive? ? (actual.to_f / target * 100).round(1) : 0 }
  end

  def defect_kpi
    today_results = ProductionResult.by_date(@date)
    good = today_results.sum(:good_qty)
    defect = today_results.sum(:defect_qty)
    total = good + defect
    rate = total.positive? ? (defect.to_f / total * 100).round(1) : 0
    { rate: rate, target: 2.0, good_count: good, defect_count: defect }
  end

  def equipment_kpi
    equipments = Equipment.active
    { rate: calculate_equipment_rate(equipments), running: equipments.run.count,
      idle: equipments.idle.count, error: equipments.down.count, pm: equipments.pm.count }
  end

  def work_order_kpi
    { in_progress: WorkOrder.in_progress.count,
      planned: WorkOrder.planned.count,
      completed: WorkOrder.where(status: :completed).where(updated_at: @date.all_day).count }
  end

  def daily_production_target
    WorkOrder.where(plan_date: @date).sum(:order_qty)
  end

  def daily_target(process)
    # 공정별 일일 목표: 해당 공정의 작업지시 합계를 기준
    200 # TODO: 공정별 목표 수량 설정 기능 추가 시 대체
  end

  def process_status(process)
    running_eq = process.equipments.run.count
    running_eq.positive? ? "running" : "idle"
  end

  def equipment_time(equipment)
    last_result = equipment.production_results.order(created_at: :desc).first
    return "대기중" unless last_result&.start_time
    elapsed = Time.current - last_result.start_time
    format_elapsed(elapsed)
  end

  def calculate_equipment_rate(equipments)
    total = equipments.count
    return 0 if total.zero?
    (equipments.run.count.to_f / total * 100).round(1)
  end

  def format_elapsed(seconds)
    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    hours.positive? ? "#{hours}h #{minutes}m" : "#{minutes}m"
  end
end
```

---

## 6. UI/UX 설계

### 6.1 화면 목록

| 화면 | URL | 설명 |
|------|-----|------|
| 대시보드 | / | KPI, 공정현황, 설비상태, 최근실적 |
| 제품 마스터 목록 | /masters/products | 제품 CRUD (검색/페이지네이션) |
| 공정 마스터 목록 | /masters/manufacturing_processes | 공정 CRUD |
| 설비 마스터 목록 | /masters/equipments | 설비 CRUD |
| 작업자 마스터 목록 | /masters/workers | 작업자 CRUD |
| 불량코드 목록 | /masters/defect_codes | 불량코드 CRUD |
| 작업지시 목록 | /productions/work_orders | 작업지시 관리 |
| 작업지시 등록 | /productions/work_orders/new | 작업지시 등록 폼 |
| 생산실적 목록 | /productions/production_results | 생산실적 조회 |
| 생산실적 입력 | /productions/production_results/new | 생산실적 입력 폼 |

### 6.2 공통 UI 패턴

#### 마스터 목록 화면 레이아웃

```
┌─────────────────────────────────────────────────┐
│  페이지 제목                      [+ 신규 등록]   │
├─────────────────────────────────────────────────┤
│  검색 필터 영역 (Ransack)                         │
│  [검색어 입력] [그룹 선택] [검색] [초기화]            │
├─────────────────────────────────────────────────┤
│  데이터 테이블                                    │
│  ┌────┬──────┬──────┬──────┬────────┐          │
│  │ No │ 코드  │ 이름  │ 그룹  │ 관리     │          │
│  ├────┼──────┼──────┼──────┼────────┤          │
│  │ 1  │ ...  │ ...  │ ...  │ [수정][삭제] │      │
│  └────┴──────┴──────┴──────┴────────┘          │
├─────────────────────────────────────────────────┤
│  페이지네이션 (Pagy)                               │
│  < 1 2 3 ... 10 >                                │
└─────────────────────────────────────────────────┘
```

#### 폼 화면 레이아웃

```
┌─────────────────────────────────────────────────┐
│  페이지 제목                                      │
├─────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────┐│
│  │ 라벨                                        ││
│  │ [입력 필드]                                  ││
│  │                                             ││
│  │ 라벨                                        ││
│  │ [입력 필드]                                  ││
│  │                                             ││
│  │ [저장]  [취소]                                ││
│  └─────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

#### 생산실적 입력 화면 (터치 최적화)

```
┌─────────────────────────────────────────────────┐
│  생산실적 입력                                     │
├─────────────────────────────────────────────────┤
│  작업지시: [WO-20260211-001 선택 ▾]              │
│  공정:    [권선 선택 ▾]                           │
│  설비:    [권선기 #1 선택 ▾]                      │
│  작업자:  [홍길동 선택 ▾]                          │
├─────────────────────────────────────────────────┤
│  양품 수량     불량 수량                           │
│  ┌─────────┐  ┌─────────┐                       │
│  │   48    │  │    2    │                       │
│  └─────────┘  └─────────┘                       │
├─────────────────────────────────────────────────┤
│  불량 유형 (불량 수량 > 0 시 표시)                   │
│  [납볼] [미납] [쇼트] [크랙] [기타]                  │
├─────────────────────────────────────────────────┤
│  LOT: L-20260211-CVT-001 (자동생성)              │
│                                                  │
│  [  저장  ]   [  취소  ]                          │
└─────────────────────────────────────────────────┘
```

### 6.3 사용자 흐름

```
[대시보드] ──── 전체 현황 파악
     │
     ├── [작업지시 목록] ── [작업지시 등록] ── 작업 시작/완료
     │
     ├── [생산실적 입력] ── 작업지시 선택 → 공정/설비/작업자 선택
     │                      → 수량 입력 → LOT 자동생성 → 저장
     │                      → (불량 시) 불량유형 선택 → 불량기록
     │
     └── [기준정보] ── 제품/공정/설비/작업자/불량코드 관리
```

### 6.4 뷰 Partial 구조

```
app/views/
├── shared/
│   ├── _search_form.html.erb     # Ransack 검색 폼 공통
│   ├── _pagination.html.erb      # Pagy 페이지네이션 공통
│   ├── _flash_messages.html.erb  # 플래시 메시지 공통
│   └── _empty_state.html.erb     # 데이터 없음 상태 공통
├── masters/
│   └── products/
│       ├── index.html.erb        # 목록
│       ├── _product.html.erb     # 행 partial (Turbo 대응)
│       ├── new.html.erb          # 등록
│       ├── edit.html.erb         # 수정
│       └── _form.html.erb        # 폼 공통
├── productions/
│   ├── work_orders/
│   │   ├── index.html.erb
│   │   ├── show.html.erb
│   │   ├── new.html.erb
│   │   └── _form.html.erb
│   └── production_results/
│       ├── index.html.erb
│       ├── new.html.erb
│       └── _form.html.erb
└── dashboard/
    └── index.html.erb            # 대시보드 (실데이터 연동)
```

---

## 7. 에러 처리

### 7.1 컨트롤러 에러 처리

| 상황 | 처리 | 사용자 표시 |
|------|------|------------|
| 유효성 검증 실패 | render :new / :edit | 폼 에러 메시지 (빨간색) |
| 레코드 미발견 | rescue_from ActiveRecord::RecordNotFound | 404 페이지 |
| 삭제 실패 (참조 존재) | rescue_from ActiveRecord::DeleteRestrictionError | "관련 데이터가 있어 삭제할 수 없습니다" |
| LOT 중복 | validates uniqueness + DB constraint | "LOT 번호가 중복됩니다" |

### 7.2 플래시 메시지

```ruby
# 성공: flash[:notice]
# 경고: flash[:alert]
# 에러: flash[:error]
```

---

## 8. 보안 고려사항

- [x] Authentication concern 적용 (모든 컨트롤러에 `allow_unauthenticated_access` 미적용)
- [x] Strong Parameters로 허용 파라미터 제한
- [x] CSRF 토큰 (Rails 기본)
- [x] SQL Injection 방어 (ActiveRecord 사용)
- [x] DB unique constraint로 데이터 무결성 보장

---

## 9. 테스트 계획

### 9.1 테스트 범위

| 유형 | 대상 | 도구 |
|------|------|------|
| 모델 테스트 | validations, associations, scopes, methods | Minitest |
| 서비스 테스트 | LotGeneratorService, WorkOrderCodeGeneratorService | Minitest |
| 컨트롤러 테스트 | CRUD 동작, 인증 확인, 리다이렉트 | Minitest |

### 9.2 핵심 테스트 케이스

- [ ] Product 모델: 유효성 검증 (필수 필드, 유니크), 스코프 동작
- [ ] WorkOrder 모델: 상태 전이, progress_rate 계산
- [ ] ProductionResult 모델: defect_rate 계산, 기간별 스코프
- [ ] LotGeneratorService: LOT 번호 형식, 순차번호 증가, 중복 방지
- [ ] WorkOrderCodeGeneratorService: 코드 형식, 순차번호 증가
- [ ] DashboardQueryService: KPI 계산 정확성
- [ ] Masters 컨트롤러: CRUD 동작, 인증 필요
- [ ] Productions 컨트롤러: 생산실적 입력 → LOT 생성 흐름

---

## 10. 시드 데이터

### 10.1 기준정보 시드

```ruby
# db/seeds.rb

# 공정 마스터 (8개 공정)
processes = [
  { process_code: "P010", process_name: "슬리팅",      process_order: 1, std_cycle_time: 30 },
  { process_code: "P020", process_name: "권선",        process_order: 2, std_cycle_time: 120 },
  { process_code: "P030", process_name: "조립",        process_order: 3, std_cycle_time: 90 },
  { process_code: "P040", process_name: "몰딩/함침",    process_order: 4, std_cycle_time: 180 },
  { process_code: "P050", process_name: "가공",        process_order: 5, std_cycle_time: 60 },
  { process_code: "P060", process_name: "검사",        process_order: 6, std_cycle_time: 45 },
  { process_code: "P070", process_name: "포장",        process_order: 7, std_cycle_time: 20 },
  { process_code: "P080", process_name: "출하",        process_order: 8, std_cycle_time: 15 }
]

# 제품 마스터 (4개 제품군)
products = [
  { product_code: "CVT-001", product_name: "OBC+LDC 통합 컨버터",    product_group: :converter },
  { product_code: "CVT-002", product_name: "LDC 단독 컨버터",         product_group: :converter },
  { product_code: "TFI-001", product_name: "고주파 트랜스포머 (3.3kW)", product_group: :transformer_inductor },
  { product_code: "TFI-002", product_name: "파워 인덕터 (100uH)",     product_group: :transformer_inductor },
  { product_code: "ELC-001", product_name: "파워 반도체 모듈",         product_group: :electronic_component },
  { product_code: "PCB-001", product_name: "메인 제어 PCBA",         product_group: :circuit_board },
  { product_code: "PCB-002", product_name: "전력 변환 PCBA",         product_group: :circuit_board }
]

# 불량코드
defect_codes = [
  { code: "D01", name: "납볼 (Solder Ball)",     description: "납 볼이 발생하여 쇼트 위험" },
  { code: "D02", name: "미납 (Insufficient)",    description: "납 량이 부족한 상태" },
  { code: "D03", name: "쇼트 (Short)",           description: "인접 패드간 납 브릿지" },
  { code: "D04", name: "크랙 (Crack)",           description: "코어 또는 기판에 크랙 발생" },
  { code: "D05", name: "오삽 (Wrong Component)", description: "잘못된 부품이 실장됨" },
  { code: "D06", name: "미삽 (Missing)",         description: "부품이 실장되지 않음" },
  { code: "D07", name: "들뜸 (Lifted)",          description: "부품이 들려있는 상태" },
  { code: "D08", name: "특성불량 (Out of Spec)",  description: "전기적 특성이 규격 벗어남" },
  { code: "D09", name: "외관불량 (Cosmetic)",     description: "스크래치, 찍힘, 오염 등" },
  { code: "D10", name: "기타 (Others)",          description: "기타 분류 불가 불량" }
]

# 설비 (공정별 1~2대)
# 작업자 (5~10명)
# 상세 시드 데이터는 구현 시 작성
```

---

## 11. 구현 순서

### 11.1 파일 구조

```
app/
├── controllers/
│   ├── concerns/
│   │   └── authentication.rb          # (기존)
│   ├── application_controller.rb      # (기존)
│   ├── dashboard_controller.rb        # (수정: DashboardQueryService 연동)
│   ├── masters/
│   │   ├── products_controller.rb     # (신규)
│   │   ├── manufacturing_processes_controller.rb  # (신규)
│   │   ├── equipments_controller.rb   # (신규)
│   │   ├── workers_controller.rb      # (신규)
│   │   └── defect_codes_controller.rb # (신규)
│   └── productions/
│       ├── work_orders_controller.rb  # (신규)
│       └── production_results_controller.rb  # (신규)
├── models/
│   ├── product.rb                     # (신규)
│   ├── manufacturing_process.rb       # (신규)
│   ├── equipment.rb                   # (신규)
│   ├── worker.rb                      # (신규)
│   ├── defect_code.rb                 # (신규)
│   ├── work_order.rb                  # (신규)
│   ├── production_result.rb           # (신규)
│   └── defect_record.rb              # (신규)
├── services/
│   ├── lot_generator_service.rb       # (신규)
│   ├── work_order_code_generator_service.rb  # (신규)
│   └── dashboard_query_service.rb     # (신규)
└── views/
    ├── shared/                        # (신규: 공통 partial)
    ├── masters/                       # (신규: 기준정보 뷰)
    ├── productions/                   # (신규: 생산관리 뷰)
    └── dashboard/
        └── index.html.erb            # (수정: 실데이터 연동)
```

### 11.2 구현 순서 (의존성 기반)

| 단계 | 작업 | 파일 | 의존성 |
|------|------|------|--------|
| **Step 1** | DB 마이그레이션 생성 | db/migrate/*.rb | 없음 |
| **Step 2** | 모델 생성 (associations, validations, scopes) | app/models/*.rb | Step 1 |
| **Step 3** | 시드 데이터 작성 | db/seeds.rb | Step 2 |
| **Step 4** | 공통 partial 생성 | app/views/shared/*.erb | 없음 |
| **Step 5** | Masters 컨트롤러 + 뷰 (5개) | app/controllers/masters/, app/views/masters/ | Step 2, 4 |
| **Step 6** | 사이드바 메뉴 URL 연동 | app/views/layouts/_sidebar.html.erb | Step 5 |
| **Step 7** | Service Objects 생성 | app/services/*.rb | Step 2 |
| **Step 8** | WorkOrders 컨트롤러 + 뷰 | app/controllers/productions/, app/views/productions/ | Step 5, 7 |
| **Step 9** | ProductionResults 컨트롤러 + 뷰 | 위와 동일 | Step 7, 8 |
| **Step 10** | DashboardController 실데이터 연동 | app/controllers/dashboard_controller.rb, app/views/dashboard/ | Step 7 |
| **Step 11** | 라우팅 업데이트 | config/routes.rb | Step 5, 8, 9 |
| **Step 12** | 테스트 작성 | test/ | Step 2~10 |

---

## 버전 이력

| 버전 | 날짜 | 변경 사항 | 작성자 |
|------|------|----------|--------|
| 0.1 | 2026-02-11 | 초안 작성 | GnT Dev Team |
