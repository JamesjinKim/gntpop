# GnT POP MVP 개발 계획서

> **Minimum Viable Product** - 핵심 가치에 집중한 최소 기능 제품
> 목표 기간: 4-6주

---

## 1. MVP 목표

### 1.1 핵심 가치 정의

```
┌─────────────────────────────────────────────────────────────┐
│                     MVP 핵심 가치                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 작업자가 작업지시를 조회하고 생산실적을 입력할 수 있다                │
│  2. 검사자가 공정검사/출하검사 결과를 입력할 수 있다                    │
│  3. 관리자가 일일 생산현황/불량률을 대시보드에서 확인할 수 있다            │
│  4. LOT 번호 자동 생성으로 제품 추적성을 확보할 수 있다                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 MoSCoW 우선순위

| 분류 | 기능 | MVP 포함 |
|------|------|----------|
| **Must Have** | 작업지시, 생산실적, LOT 추적, 공정검사, 출하검사, 일일 대시보드 | ✅ |
| **Should Have** | 설비 가동률, 주간/월간 KPI | ❌ (Post-MVP) |
| **Could Have** | PDF 보고서, BOM 관리, SPC 차트 | ❌ (Post-MVP) |
| **Won't Have** | PLC 연동, ERP 연동, AI 예지보전 | ❌ (6개월 이후) |

---

## 2. 기술 스택

### 2.1 핵심 기술

| 구분 | 기술 | 비고 |
|------|------|------|
| **Backend** | Ruby on Rails 8.0 | Hotwire (Turbo + Stimulus) |
| **Database** | SQLite3 | 개발/MVP, 추후 PostgreSQL 전환 |
| **Frontend** | Tailwind CSS v4 | GnT 브랜드 색상 테마 |
| **인증** | Rails 8 Authentication | 내장 인증 생성기 |
| **차트** | Chartkick + Groupdate | 간단한 KPI 차트 |
| **페이지네이션** | Pagy | 경량 페이지네이션 |

### 2.2 MVP에서 제외된 기술

| 기술 | 이유 | 대안 |
|------|------|------|
| ActionCable | 복잡도 증가 | 30초 자동 새로고침 |
| Solid Queue | MVP에 불필요 | 실시간 조회 |
| Prawn PDF | MVP에 불필요 | CSV 다운로드 |
| Ransack | 과도한 검색 기능 | 기본 where 필터 |

---

## 3. Phase 구성 (3단계)

### 3.1 전체 구조

```
┌─────────────────────────────────────────────────────────────┐
│                    MVP 개발 Phase (4-6주)                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Phase 1: 기반 구축 (1주)                     ✅ 완료         │
│  ├─ Rails 8 프로젝트 생성                                    │
│  ├─ 인증 시스템                                              │
│  ├─ 메인 레이아웃 + 사이드바                                  │
│  ├─ Tailwind CSS 테마                                       │
│  └─ 대시보드 UI                                              │
│                                                             │
│  Phase 2: 핵심 기능 (2-3주)                   ⬜ 진행 예정     │
│  ├─ 기준정보 CRUD (제품/공정/작업자/불량코드)                  │
│  ├─ 작업지시 등록/조회                                        │
│  ├─ 생산실적 입력 (터치 UI)                                   │
│  ├─ LOT 번호 자동생성                                        │
│  ├─ 공정검사/출하검사 입력                                    │
│  └─ 불량 기록 및 집계                                        │
│                                                             │
│  Phase 3: 모니터링 & 안정화 (1-2주)           ⬜ 진행 예정     │
│  ├─ 대시보드 실제 데이터 연동                                 │
│  ├─ 불량률 추이 차트                                         │
│  ├─ 공정별 재공품(WIP) 현황                                  │
│  ├─ 버그 수정 및 성능 최적화                                  │
│  └─ 현장 테스트 및 피드백 반영                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Phase 1: 기반 구축 (완료)

### 4.1 완료 항목

- [x] Rails 8 프로젝트 생성
- [x] Tailwind CSS v4 설정
- [x] GnT 브랜드 색상 테마 (@theme 블록)
- [x] 인증 시스템 (Rails Authentication)
- [x] 메인 레이아웃 (사이드바 + 헤더)
- [x] 대시보드 UI (60-30-10 색상 비율)
- [x] 반응형 레이아웃

### 4.2 산출물

| 파일 | 설명 |
|------|------|
| `app/views/layouts/application.html.erb` | 메인 레이아웃 |
| `app/views/layouts/_sidebar.html.erb` | 사이드바 네비게이션 |
| `app/views/dashboard/index.html.erb` | 대시보드 UI |
| `app/assets/tailwind/application.css` | GnT 테마 정의 |

---

## 5. Phase 2: 핵심 기능 (2-3주)

### 5.1 기준정보 관리

#### 5.1.1 제품 마스터 (Products)

```ruby
# db/migrate/create_products.rb
create_table :products do |t|
  t.string :code, null: false          # 제품코드
  t.string :name, null: false          # 제품명
  t.integer :product_group, null: false # 제품군 (enum)
  t.string :specification              # 규격
  t.string :unit, default: 'EA'        # 단위
  t.boolean :active, default: true     # 사용여부
  t.timestamps
end

# enum product_group:
#   converter: 0, transformer_inductor: 1,
#   electronic_component: 2, circuit_board: 3
```

**화면 기능:**
- 목록 조회 (제품군별 필터)
- 등록/수정/삭제
- 사용여부 토글

#### 5.1.2 공정 마스터 (Processes)

```ruby
# db/migrate/create_manufacturing_processes.rb
create_table :manufacturing_processes do |t|
  t.string :code, null: false          # 공정코드
  t.string :name, null: false          # 공정명
  t.integer :process_order, null: false # 공정순서
  t.integer :standard_time             # 표준 사이클타임 (초)
  t.boolean :active, default: true
  t.timestamps
end
```

**시드 데이터 (8개 공정):**
1. 슬리팅 (SLT)
2. 권선 (WND)
3. 조립 (ASM)
4. 몰딩/함침 (MLD)
5. 가공 (PRC)
6. 검사 (INS)
7. 포장 (PKG)
8. 출하 (SHP)

#### 5.1.3 작업자 마스터 (Workers)

```ruby
# db/migrate/create_workers.rb
create_table :workers do |t|
  t.string :employee_number, null: false  # 사원번호
  t.string :name, null: false             # 성명
  t.references :manufacturing_process     # 담당 공정
  t.boolean :active, default: true
  t.timestamps
end
```

#### 5.1.4 불량코드 마스터 (DefectCodes)

```ruby
# db/migrate/create_defect_codes.rb
create_table :defect_codes do |t|
  t.string :code, null: false          # 불량코드
  t.string :name, null: false          # 불량명
  t.string :description                # 설명
  t.boolean :active, default: true
  t.timestamps
end
```

**시드 데이터:**
- D01: 외관불량
- D02: 치수불량
- D03: 전기특성불량
- D04: 절연불량
- D05: 기타

---

### 5.2 생산관리

#### 5.2.1 작업지시 (WorkOrders)

```ruby
# db/migrate/create_work_orders.rb
create_table :work_orders do |t|
  t.string :wo_number, null: false     # 작업지시번호 (WO-YYYYMMDD-NNN)
  t.references :product, null: false
  t.integer :order_qty, null: false    # 지시수량
  t.date :due_date                     # 납기일
  t.integer :priority, default: 5      # 우선순위 (1-10)
  t.integer :status, default: 0        # 상태 (enum)
  t.timestamps
end

# enum status: plan: 0, in_progress: 1, completed: 2, cancelled: 3
```

**자동 채번 로직:**
```ruby
# app/services/work_order_number_generator.rb
class WorkOrderNumberGenerator
  def self.generate
    date = Date.current.strftime('%Y%m%d')
    seq = WorkOrder.where('wo_number LIKE ?', "WO-#{date}-%").count + 1
    "WO-#{date}-#{seq.to_s.rjust(3, '0')}"
  end
end
```

**화면 기능:**
- 작업지시 목록 (날짜/상태 필터)
- 작업지시 등록 (제품 선택, 수량 입력)
- 작업지시 상태 변경 (계획→진행→완료)

#### 5.2.2 생산실적 (ProductionResults)

```ruby
# db/migrate/create_production_results.rb
create_table :production_results do |t|
  t.references :work_order, null: false
  t.references :manufacturing_process, null: false
  t.references :worker
  t.string :lot_number, null: false    # LOT 번호
  t.integer :good_qty, default: 0      # 양품수량
  t.integer :defect_qty, default: 0    # 불량수량
  t.datetime :start_time               # 작업시작
  t.datetime :end_time                 # 작업종료
  t.timestamps
end
```

**LOT 번호 자동생성:**
```ruby
# app/services/lot_number_generator.rb
class LotNumberGenerator
  def self.generate(product_code)
    date = Date.current.strftime('%y%m%d')
    seq = ProductionResult.where('lot_number LIKE ?', "#{date}#{product_code}%")
                          .count + 1
    "#{date}#{product_code}#{seq.to_s.rjust(4, '0')}"
  end
end
```

**터치 UI 실적 입력:**
- 작업지시 바코드 스캔 → 자동 조회
- 공정 선택 (버튼)
- 숫자 키패드로 수량 입력
- 큰 버튼 (최소 44px 터치 타겟)

```erb
<!-- 터치 최적화 숫자 입력 -->
<div class="grid grid-cols-3 gap-2">
  <% (1..9).each do |n| %>
    <button type="button"
            class="h-14 text-2xl font-bold bg-slate-100 rounded-lg
                   hover:bg-slate-200 active:bg-slate-300"
            data-action="click->numpad#input"
            data-value="<%= n %>">
      <%= n %>
    </button>
  <% end %>
</div>
```

---

### 5.3 품질관리

#### 5.3.1 검사결과 (InspectionResults)

```ruby
# db/migrate/create_inspection_results.rb
create_table :inspection_results do |t|
  t.references :production_result, null: false
  t.integer :inspection_type, null: false  # 검사유형 (enum)
  t.decimal :voltage, precision: 10, scale: 3      # 전압
  t.decimal :current, precision: 10, scale: 3      # 전류
  t.decimal :insulation, precision: 10, scale: 3   # 절연저항
  t.integer :judgment, null: false         # 판정 (enum)
  t.text :remarks                          # 비고
  t.references :inspector                  # 검사자 (Worker)
  t.timestamps
end

# enum inspection_type: process: 0, outgoing: 1
# enum judgment: pass: 0, fail: 1
```

**자동 판정 로직:**
```ruby
# app/models/inspection_result.rb
class InspectionResult < ApplicationRecord
  before_validation :auto_judge

  private

  def auto_judge
    return if voltage.nil? || current.nil?

    # 제품별 규격 범위 체크 (예시)
    voltage_ok = voltage.between?(spec_min_voltage, spec_max_voltage)
    current_ok = current.between?(spec_min_current, spec_max_current)

    self.judgment = (voltage_ok && current_ok) ? :pass : :fail
  end
end
```

#### 5.3.2 불량기록 (DefectRecords)

```ruby
# db/migrate/create_defect_records.rb
create_table :defect_records do |t|
  t.references :production_result, null: false
  t.references :defect_code, null: false
  t.integer :quantity, null: false, default: 1
  t.text :description
  t.timestamps
end
```

**불량 파레토 차트:**
```erb
<!-- 불량유형별 파레토 차트 -->
<%= column_chart DefectRecord.joins(:defect_code)
                             .group('defect_codes.name')
                             .sum(:quantity),
                 title: "불량유형별 현황" %>
```

---

## 6. Phase 3: 모니터링 & 안정화 (1-2주)

### 6.1 대시보드 실제 데이터 연동

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def index
    @today_production = ProductionResult.where(created_at: Date.current.all_day)
    @good_total = @today_production.sum(:good_qty)
    @defect_total = @today_production.sum(:defect_qty)
    @defect_rate = calculate_defect_rate(@good_total, @defect_total)

    @process_status = manufacturing_process_status
    @recent_results = ProductionResult.includes(:work_order, :manufacturing_process)
                                      .order(created_at: :desc)
                                      .limit(10)
  end

  private

  def calculate_defect_rate(good, defect)
    total = good + defect
    return 0 if total.zero?
    (defect.to_f / total * 100).round(2)
  end

  def manufacturing_process_status
    ManufacturingProcess.active.map do |process|
      results = ProductionResult.where(
        manufacturing_process: process,
        created_at: Date.current.all_day
      )
      {
        process: process,
        good_qty: results.sum(:good_qty),
        target_qty: daily_target(process)
      }
    end
  end
end
```

### 6.2 KPI 차트

```erb
<!-- 일별 불량률 추이 (최근 7일) -->
<%= line_chart ProductionResult.where('created_at >= ?', 7.days.ago)
                               .group_by_day(:created_at)
                               .sum('defect_qty * 100.0 / NULLIF(good_qty + defect_qty, 0)'),
               title: "일별 불량률 추이 (%)",
               suffix: "%" %>
```

### 6.3 자동 새로고침 (ActionCable 대체)

```erb
<!-- 30초 자동 새로고침 -->
<meta http-equiv="refresh" content="30">

<!-- 또는 Turbo Frame 사용 -->
<%= turbo_frame_tag "dashboard_stats",
                    src: dashboard_stats_path,
                    loading: :lazy do %>
  <%= render "stats_loading" %>
<% end %>
```

---

## 7. 데이터베이스 ERD

```
┌─────────────────┐     ┌─────────────────┐
│    products     │     │manufacturing_   │
├─────────────────┤     │   processes     │
│ id              │     ├─────────────────┤
│ code            │     │ id              │
│ name            │     │ code            │
│ product_group   │     │ name            │
│ specification   │     │ process_order   │
│ unit            │     │ standard_time   │
│ active          │     │ active          │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │    ┌──────────────────┤
         │    │                  │
         ▼    ▼                  ▼
┌─────────────────┐     ┌─────────────────┐
│   work_orders   │     │    workers      │
├─────────────────┤     ├─────────────────┤
│ id              │     │ id              │
│ wo_number       │     │ employee_number │
│ product_id (FK) │     │ name            │
│ order_qty       │     │ process_id (FK) │
│ due_date        │     │ active          │
│ priority        │     └────────┬────────┘
│ status          │              │
└────────┬────────┘              │
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────┐
│          production_results             │
├─────────────────────────────────────────┤
│ id                                      │
│ work_order_id (FK)                      │
│ manufacturing_process_id (FK)           │
│ worker_id (FK)                          │
│ lot_number                              │
│ good_qty                                │
│ defect_qty                              │
│ start_time                              │
│ end_time                                │
└────────┬───────────────┬────────────────┘
         │               │
         ▼               ▼
┌─────────────────┐  ┌─────────────────┐
│inspection_      │  │ defect_records  │
│   results       │  ├─────────────────┤
├─────────────────┤  │ id              │
│ id              │  │ production_     │
│ production_     │  │   result_id(FK) │
│   result_id(FK) │  │ defect_code_id  │
│ inspection_type │  │   (FK)          │
│ voltage         │  │ quantity        │
│ current         │  │ description     │
│ insulation      │  └─────────────────┘
│ judgment        │           ▲
│ inspector_id    │           │
└─────────────────┘  ┌────────┴────────┐
                     │  defect_codes   │
                     ├─────────────────┤
                     │ id              │
                     │ code            │
                     │ name            │
                     │ description     │
                     │ active          │
                     └─────────────────┘
```

---

## 8. 화면 목록

### 8.1 MVP 화면 (필수)

| 메뉴 | 화면 | 설명 |
|------|------|------|
| 대시보드 | 메인 대시보드 | KPI, 공정별 현황, 최근 실적 |
| 기준정보 | 제품 관리 | CRUD |
| 기준정보 | 공정 관리 | CRUD |
| 기준정보 | 작업자 관리 | CRUD |
| 기준정보 | 불량코드 관리 | CRUD |
| 생산관리 | 작업지시 목록 | 조회, 필터 |
| 생산관리 | 작업지시 등록 | 신규 등록 |
| 생산관리 | 생산실적 입력 | 터치 UI |
| 품질관리 | 검사결과 입력 | 공정/출하검사 |
| 품질관리 | 불량 현황 | 파레토 차트 |

### 8.2 Post-MVP 화면 (향후)

| 메뉴 | 화면 | 예정 Phase |
|------|------|-----------|
| 설비관리 | 설비 상태 모니터링 | Phase 4 |
| 품질관리 | SPC 관리도 | Phase 4 |
| 보고서 | PDF 보고서 출력 | Phase 5 |
| 설정 | BOM 관리 | Phase 5 |

---

## 9. 검증 체크리스트

### 9.1 Phase 1 완료 검증 ✅

- [x] 로그인/로그아웃 정상 동작
- [x] 대시보드 화면 표시
- [x] GnT 브랜드 색상 적용
- [x] 반응형 레이아웃 (모바일 대응)

### 9.2 Phase 2 완료 검증

- [ ] 기준정보 CRUD 정상 동작
- [ ] 작업지시 등록 → 번호 자동 채번
- [ ] 생산실적 입력 → LOT 번호 자동 생성
- [ ] 터치 UI로 수량 입력 가능 (태블릿 테스트)
- [ ] 검사결과 입력 → 자동 판정
- [ ] 불량 기록 → 파레토 차트 표시

### 9.3 Phase 3 완료 검증

- [ ] 대시보드에 실제 데이터 표시
- [ ] 일일 생산량/불량률 정확히 계산
- [ ] 공정별 진척률 표시
- [ ] 30초 자동 새로고침 동작
- [ ] 현장 작업자 테스트 완료
- [ ] 주요 버그 수정 완료

---

## 10. 일정 요약

```
┌─────────────────────────────────────────────────────────────┐
│                    MVP 개발 일정 (4-6주)                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Week 1: Phase 1 기반 구축                    ✅ 완료        │
│                                                             │
│  Week 2-3: Phase 2 핵심 기능                                │
│    - 기준정보 CRUD                                          │
│    - 작업지시/생산실적                                       │
│    - 품질검사/불량기록                                       │
│                                                             │
│  Week 4-5: Phase 3 모니터링 & 안정화                        │
│    - 대시보드 데이터 연동                                    │
│    - 현장 테스트                                            │
│    - 버그 수정                                              │
│                                                             │
│  Week 6: MVP 릴리스                                         │
│    - 최종 테스트                                            │
│    - 사용자 교육                                            │
│    - 현장 투입                                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 11. Post-MVP 로드맵

MVP 완료 후 실제 운영 데이터를 기반으로 다음 기능을 단계적으로 추가합니다.

| Phase | 기능 | 예상 시기 |
|-------|------|----------|
| Phase 4 | 설비 가동률, SPC 관리도, 수입검사 | MVP +1개월 |
| Phase 5 | PDF 보고서, BOM 관리, 주간/월간 KPI | MVP +2개월 |
| Phase 6 | PLC 연동, ERP 인터페이스, PWA | MVP +6개월 |

상세 기능은 `GNT_POP_PLAN.md` 참조

---

> **문서 버전**: v1.0
> **작성일**: 2026-02-10
> **작성**: 신호테크놀로지 × Claude AI
