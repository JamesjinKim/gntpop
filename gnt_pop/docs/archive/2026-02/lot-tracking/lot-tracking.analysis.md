# LOT Tracking (lot-tracking) Gap Analysis Report

> **Analysis Type**: Gap Analysis (Design vs Implementation)
>
> **Project**: GnT POP (v0.1.0)
> **Analyst**: Gap Detector Agent
> **Date**: 2026-02-12
> **Design Doc**: [lot-tracking.design.md](../02-design/features/lot-tracking.design.md)
> **Plan Doc**: [lot-tracking.plan.md](../01-plan/features/lot-tracking.plan.md)

---

## 1. Analysis Overview

### 1.1 Analysis Purpose

lot-tracking 기능의 설계 문서(Design)와 실제 구현 코드(Do) 간의 일치율을 검증하고, 차이점을 식별하여 품질 보증 및 후속 조치를 결정한다.

### 1.2 Analysis Scope

| 항목 | 경로 |
|------|------|
| Design Document | `docs/02-design/features/lot-tracking.design.md` |
| Plan Document | `docs/01-plan/features/lot-tracking.plan.md` |
| Controller | `app/controllers/productions/lot_tracking_controller.rb` |
| Views | `app/views/productions/lot_tracking/{index,show}.html.erb` |
| Routes | `config/routes.rb` |
| Sidebar | `app/views/layouts/_sidebar.html.erb` |
| Model | `app/models/production_result.rb` |

---

## 2. Overall Scores

| Category | Score | Status |
|----------|:-----:|:------:|
| Design Match | 91% | PASS |
| Architecture Compliance | 100% | PASS |
| Convention Compliance | 98% | PASS |
| **Overall** | **93%** | **PASS** |

```
Overall Match Rate: 93%

  PASS Match:          26 items (91%)
  WARN Added (not in design): 2 items (7%)
  FAIL Not implemented:     1 item  (3%)
```

---

## 3. Feature-by-Feature Comparison (FR-01 ~ FR-09)

### 3.1 Plan Requirements vs Implementation

| ID | Requirement | Design | Implementation | Status | Notes |
|----|-------------|:------:|:--------------:|:------:|-------|
| FR-01 | LOT 번호 검색 전용 화면 제공 | O | O | PASS | index.html.erb 구현됨 |
| FR-02 | LOT 번호 입력 시 해당 생산실적 상세 정보 표시 | O | O | PASS | show.html.erb 구현됨 |
| FR-03 | LOT에 연결된 작업지시 정보 표시 | O | O | PASS | 작업지시코드, 제품, 수량, 상태, 계획일 모두 표시 |
| FR-04 | LOT의 공정/설비/작업자 정보 표시 | O | O | PASS | 공정/설비/작업자 카드 구현됨 |
| FR-05 | LOT의 양품/불량 수량 및 불량률 표시 | O | O | PASS | LOT 기본정보 카드에 표시 |
| FR-06 | LOT에 연결된 불량기록 목록 표시 | O | O | PASS | 불량 테이블 + 합계 행 구현됨 |
| FR-07 | LOT 작업 타임라인 표시 | O | O | PASS | 시작/종료/소요시간 + 타임라인 바 구현됨 |
| FR-08 | LOT 미발견 시 안내 메시지 표시 | O | O | PASS | 경고 메시지 박스 구현됨 |
| FR-09 | 최근 검색 LOT 이력 표시 (세션 기반) | O | Partial | WARN | 아래 상세 설명 참조 |

---

## 4. Detailed Comparison

### 4.1 Routing Comparison

| Design | Implementation | Status |
|--------|---------------|:------:|
| `namespace :productions do` | `namespace :productions do` | PASS |
| `resources :lot_tracking, only: [:index, :show], param: :lot_no` | `resources :lot_tracking, only: [ :index, :show ], param: :lot_no` | PASS |
| GET /productions/lot_tracking | GET /productions/lot_tracking | PASS |
| GET /productions/lot_tracking/:lot_no | GET /productions/lot_tracking/:lot_no | PASS |

**Routing: 100% Match**

### 4.2 Controller Comparison

| 항목 | Design (design.md Section 4) | Implementation | Status |
|------|------------------------------|---------------|:------:|
| Class 이름 | `Productions::LotTrackingController` | `Productions::LotTrackingController` | PASS |
| 상속 | `< ApplicationController` | `< ApplicationController` | PASS |
| index: lot_no 파라미터 검색 | `params[:lot_no].present?` 체크 | `params[:lot_no].present?` 체크 | PASS |
| index: strip 처리 | `params[:lot_no].strip` | `params[:lot_no].strip` | PASS |
| index: 발견 시 리다이렉트 | `redirect_to productions_lot_tracking_path` | `redirect_to productions_lot_tracking_path` | PASS |
| index: 미발견 시 플래그 | `@not_found = true` | `@not_found = true` | PASS |
| index: 최근 LOT 목록 | (설계서에 명시 없음) | `@recent_results` 변수로 구현 | INFO |
| show: LOT 조회 | `find_by_lot_no(params[:lot_no])` | `find_by_lot_no(params[:lot_no])` | PASS |
| show: 불량기록 조회 | `@defect_records = @production_result.defect_records.includes(:defect_code)` | 동일 | PASS |
| show: RecordNotFound 처리 방식 | `rescue ActiveRecord::RecordNotFound` | `unless @production_result` + redirect | CHANGED |
| private: find_by_lot_no | `find_by` 방식 | `find_by` 방식 | PASS |
| private: eager loading | `includes(work_order: :product, manufacturing_process: {}, equipment: {}, worker: {}, defect_records: :defect_code)` | 동일 | PASS |
| frozen_string_literal | (언급 없음) | `# frozen_string_literal: true` 추가됨 | INFO |

**Controller: 95% Match (1 Changed)**

### 4.3 View Comparison - index.html.erb

| 설계 UI 요소 | Implementation | Status |
|-------------|---------------|:------:|
| 페이지 제목 "LOT 추적" | `<h1>LOT 추적</h1>` | PASS |
| 설명 텍스트 | "LOT 번호로 생산 이력을 조회합니다." | PASS |
| 검색 폼 (텍스트 입력 + 검색 버튼) | `form_tag` + `text_field_tag :lot_no` + 검색 버튼 | PASS |
| placeholder 예시 | LOT 번호 형식 예시 | PASS |
| 미발견 메시지 (경고 박스) | `@not_found` 조건부 경고 박스 | PASS |
| 미발견 메시지 텍스트 | "에 해당하는 LOT을 찾을 수 없습니다." | PASS |
| 최근 생산 LOT 테이블 | 6-column 테이블 구현 | PASS |
| 테이블 컬럼: LOT 번호 | O | PASS |
| 테이블 컬럼: 제품 | O | PASS |
| 테이블 컬럼: 공정 | O (설계서에는 없지만 추가됨) | INFO |
| 테이블 컬럼: 양품 수량 | O (설계서에는 "수량"으로 표기) | PASS |
| 테이블 컬럼: 불량 수량 | O (설계서에는 없지만 추가됨) | INFO |
| 테이블 컬럼: 등록일시 | O | PASS |
| 클릭 시 상세 이동 | `onclick` 이벤트로 구현 | PASS |
| 데이터 없을 때 빈 상태 | "생산실적 데이터가 없습니다." | PASS |

**Index View: 100% Match (2 Enhancement)**

### 4.4 View Comparison - show.html.erb

| 설계 UI 요소 | Implementation | Status |
|-------------|---------------|:------:|
| Breadcrumb (LOT 추적 > LOT번호) | `link_to "LOT 추적"` + 현재 LOT번호 | PASS |
| 돌아가기 버튼 | `link_to productions_lot_tracking_index_path` "돌아가기" | PASS |
| **LOT 기본 정보 카드** | | |
| - LOT 번호 | `result.lot_no` | PASS |
| - 등록일시 | `result.created_at.strftime` | PASS |
| - 양품/불량 수량 | `good_qty / defect_qty` | PASS |
| - 불량률 | `result.defect_rate` | PASS |
| **작업지시 정보 카드** | | |
| - 작업지시코드 | `work_order.work_order_code` | PASS |
| - 제품코드 | `product.product_code` | PASS |
| - 제품명 | `product.product_name` | PASS |
| - 지시수량 | `work_order.order_qty` | PASS |
| - 상태 (badge) | status_colors/status_labels 매핑 | PASS |
| - 계획일 | `work_order.plan_date` | PASS |
| **공정/설비/작업자 카드** | | |
| - 공정 [코드] 이름 | `[process_code] process_name` | PASS |
| - 설비 [코드] 이름 | `[equipment_code] equipment_name` | PASS |
| - 설비 위치 | `equipment.location` (조건부 표시) | PASS |
| - 작업자 [사번] 이름 | `[employee_number] name` | PASS |
| **작업 시간 카드** | | |
| - 시작 시간 | `result.start_time` | PASS |
| - 종료 시간 | `result.end_time` | PASS |
| - 소요 시간 (시간/분 계산) | elapsed 계산 로직 | PASS |
| - 타임라인 바 | Tailwind progress bar | PASS |
| **불량 기록 테이블** | | |
| - 불량코드 | `record.defect_code.code` | PASS |
| - 불량유형 | `record.defect_code.name` | PASS |
| - 수량 | `record.defect_qty` | PASS |
| - 설명 | `record.description` | PASS |
| - 합계 행 | `@defect_records.sum(&:defect_qty)` | PASS |
| - 불량 없을 때 빈 상태 | "불량 기록이 없습니다." 메시지 | PASS |

**Show View: 100% Match**

### 4.5 Sidebar Link Comparison

| Design | Implementation | Status |
|--------|---------------|:------:|
| LOT 추적 링크 추가 | `link_to productions_lot_tracking_index_path` | PASS |
| 생산관리 섹션 하위 | 작업지시, 생산실적 다음 위치 | PASS |
| 활성 상태 하이라이트 | `request.path.start_with?('/productions/lot_tracking')` | PASS |
| 태그 아이콘 SVG | tag icon 적용 | PASS |

**Sidebar: 100% Match**

### 4.6 Model (ProductionResult) Comparison

| Design 요구사항 | Implementation | Status |
|----------------|---------------|:------:|
| `recent` scope 사용 | `scope :recent, -> { order(created_at: :desc) }` | PASS |
| `has_many :defect_records` | `has_many :defect_records, dependent: :destroy` | PASS |
| `belongs_to :work_order` | O | PASS |
| `belongs_to :manufacturing_process` | O | PASS |
| `belongs_to :equipment, optional: true` | O | PASS |
| `belongs_to :worker, optional: true` | O | PASS |
| `defect_rate` 메서드 | 구현됨 (percentage 반환) | PASS |
| `total_qty` 메서드 | 구현됨 | PASS |
| lot_no 인덱스 (unique) | `index_production_results_on_lot_no (unique)` | PASS |

**Model: 100% Match**

### 4.7 Error Handling Comparison

| 상황 | Design 처리 | Implementation 처리 | Status |
|------|------------|-------------------|:------:|
| LOT 번호 미입력 | index 화면 유지 | index 화면 유지 (조건문 pass) | PASS |
| LOT 미발견 (index 검색) | `@not_found` 플래그 + 경고 메시지 | 동일 | PASS |
| LOT 미발견 (show 직접 접근) | `rescue ActiveRecord::RecordNotFound` + redirect | `unless @production_result` + redirect | CHANGED |
| 인증 미완료 | Authentication concern | `include Authentication` (ApplicationController) | PASS |

**Error Handling: 95% Match (1 Changed)**

### 4.8 Security Comparison

| 보안 항목 | Design | Implementation | Status |
|----------|--------|---------------|:------:|
| Authentication concern | O | `include Authentication` 상속 | PASS |
| LOT 번호 strip 처리 | O | `params[:lot_no].strip` | PASS |
| SQL Injection 방어 | ActiveRecord find_by | find_by 사용 | PASS |
| 존재하지 않는 LOT 안전 처리 | redirect | redirect 구현 | PASS |

**Security: 100% Match**

---

## 5. Differences Found

### 5.1 MISSING - Missing Features (Design O, Implementation X)

| Item | Design Location | Description | Impact |
|------|-----------------|-------------|--------|
| FR-09 세션 기반 최근 검색 LOT | plan.md FR-09 | "최근 검색 LOT 이력 표시 (세션 기반)"이 구현되지 않음. 대신 최근 생산 LOT 목록(DB 기반)으로 대체됨 | Low (Plan에서 Low 우선순위) |

### 5.2 ADDED - Added Features (Design X, Implementation O)

| Item | Implementation Location | Description | Impact |
|------|------------------------|-------------|--------|
| index 최근 생산 LOT 목록 | lot_tracking_controller.rb L19-22, index.html.erb L40-95 | 설계서의 Section 5.2 와이어프레임에는 최근 LOT 테이블이 있으나 컨트롤러 설계(Section 4.1)에는 `@recent_results` 변수 할당이 없음. 구현에서 추가됨 | Positive |
| index 테이블 공정/불량 컬럼 | index.html.erb L53-55, L74-78 | 설계서 와이어프레임의 테이블 컬럼(LOT번호, 제품, 일시, 수량)에 공정, 불량 컬럼이 추가됨 | Positive |

### 5.3 CHANGED - Changed Features (Design != Implementation)

| Item | Design | Implementation | Impact |
|------|--------|----------------|:------:|
| show 에러 처리 방식 | `rescue ActiveRecord::RecordNotFound` (예외 기반) | `unless @production_result` (조건 분기) | Low |
| index return 문 | return 없음 (암묵적 흐름) | `return` 명시 (L12) | Low |
| frozen_string_literal | 언급 없음 | `# frozen_string_literal: true` magic comment | None |

---

## 6. Architecture Compliance

### 6.1 MVC Layer Compliance (Dynamic Level)

| Layer | Expected | Actual | Status |
|-------|----------|--------|:------:|
| Controller | `app/controllers/productions/lot_tracking_controller.rb` | 동일 | PASS |
| View (index) | `app/views/productions/lot_tracking/index.html.erb` | 동일 | PASS |
| View (show) | `app/views/productions/lot_tracking/show.html.erb` | 동일 | PASS |
| Model | 기존 `ProductionResult` 활용 | 동일 | PASS |
| Route | `config/routes.rb` namespace 하위 | 동일 | PASS |

### 6.2 Design Principles Compliance

| 원칙 | 검증 결과 | Status |
|------|----------|:------:|
| SRP (단일 책임) | LOT 추적 전용 컨트롤러로 분리됨 | PASS |
| DRY | 기존 모델/관계 활용, 새 모델 생성 없음 | PASS |
| Fat Model, Skinny Controller | `recent` scope, `defect_rate` 메서드 모델에 위치 | PASS |
| Rails Convention | RESTful routing, namespace 구조 | PASS |
| N+1 방지 | `includes()` eager loading 적용 | PASS |

**Architecture Compliance: 100%**

---

## 7. Convention Compliance

### 7.1 Naming Convention

| Category | Convention | Checked | Compliance | Violations |
|----------|-----------|:-------:|:----------:|------------|
| Controller | snake_case + PascalCase class | 1 | 100% | - |
| Views | snake_case.html.erb | 2 | 100% | - |
| Routes | RESTful resource naming | 1 | 100% | - |
| Model scopes | snake_case | 3 | 100% | - |
| Variables | snake_case | 10+ | 100% | - |

### 7.2 Code Style

| Item | Status | Notes |
|------|:------:|-------|
| frozen_string_literal magic comment | PASS | 컨트롤러에 적용됨 |
| Rubocop 스타일 (array syntax) | PASS | `only: [ :index, :show ]` Rails 스타일 |
| 들여쓰기 (2 spaces) | PASS | 전체 파일 일관성 유지 |
| 안전 네비게이션 연산자 (&.) 사용 | PASS | optional 관계에 적용됨 |

### 7.3 Tailwind CSS / UI Convention

| Item | Status | Notes |
|------|:------:|-------|
| GnT 브랜드 색상 사용 | PASS | `text-gnt-red`, `bg-gnt-red` 적용 |
| 터치 최적화 (44px+) | PASS | `py-3 px-4` 검색 입력, `px-6 py-3` 버튼 |
| 반응형 레이아웃 | PASS | `grid-cols-2 md:grid-cols-4`, `grid-cols-1 md:grid-cols-2` |
| 60-30-10 색상 비율 | PASS | 흰색/회색 기본 + GnT Red 액센트 |

**Convention Compliance: 98%**

---

## 8. Performance Considerations

| 항목 | Design 기준 | Implementation | Status |
|------|------------|---------------|:------:|
| N+1 쿼리 방지 | eager loading 필수 | `includes()` 체인 적용 | PASS |
| lot_no 인덱스 | 검색 성능 보장 | `unique index on lot_no` | PASS |
| 최근 LOT 제한 | - | `.limit(10)` 적용 | PASS |
| created_at 인덱스 | - | `index_production_results_on_created_at` | PASS |

---

## 9. Test Coverage

| Area | Status | Notes |
|------|:------:|-------|
| Controller 테스트 | FAIL | `test/controllers/productions/lot_tracking_controller_test.rb` 미작성 |
| System 테스트 | FAIL | 미작성 |
| Model 테스트 (관련) | FAIL | ProductionResult 모델 테스트 미작성 |

**Test Coverage: 0% (테스트 미작성)**

---

## 10. Overall Score Summary

```
Overall Score: 93/100

  Design Match:          91% (26/29 items)
  Architecture:         100% (5/5 checks)
  Convention:            98% (all conventions met)
  Security:             100% (4/4 checks)
  Performance:          100% (4/4 optimizations)
  Test Coverage:          0% (0/3 test files)

  Match Rate (excluding tests): 96%
  Match Rate (including tests):  93%
```

---

## 11. Recommended Actions

### 11.1 Immediate (24h)

| Priority | Item | File | Description |
|----------|------|------|-------------|
| - | 없음 | - | Critical/High 이슈 없음 |

### 11.2 Short-term (1 week)

| Priority | Item | File | Expected Impact |
|----------|------|------|-----------------|
| WARN 1 | Controller 테스트 작성 | `test/controllers/productions/lot_tracking_controller_test.rb` | 회귀 방지 |
| WARN 2 | System 테스트 작성 | `test/system/lot_tracking_test.rb` | E2E 검증 |

### 11.3 Long-term (Backlog)

| Item | Description | Priority |
|------|-------------|----------|
| FR-09 세션 기반 검색 이력 | Plan 문서의 FR-09 (Low 우선순위) 구현 또는 Plan 문서에서 Deferred로 변경 | Low |
| 설계서 컨트롤러 섹션 보완 | Section 4.1의 index 액션에 `@recent_results` 변수 할당 로직 추가 | Low |

---

## 12. Design Document Updates Needed

설계 문서를 실제 구현에 맞게 업데이트해야 할 항목:

- [ ] Section 4.1 index 액션에 `@recent_results` 변수 할당 코드 추가
- [ ] Section 4.1 index 액션에 `return` 문 추가 (redirect_to 이후)
- [ ] Section 4.1 show 액션의 에러 처리를 `unless` 조건 분기 방식으로 업데이트
- [ ] Section 5.2 와이어프레임 테이블 컬럼에 "공정", "불량" 추가
- [ ] FR-09의 상태를 "Deferred" 또는 "Replaced by DB-based recent list"로 변경

---

## 13. Synchronization Recommendation

**Match Rate >= 90%** 이므로:

> "설계와 구현이 잘 일치합니다. 아래 소규모 차이점에 대한 문서 업데이트를 권장합니다."

**권장 동기화 옵션**: **Option 2 - 설계 문서를 구현에 맞게 업데이트**

- show 에러 처리 방식 변경 (조건 분기 방식이 더 명시적이고 안전)
- index의 `@recent_results` 추가 (사용자 경험 개선)
- 테이블 컬럼 추가 (정보 밀도 향상)

---

## 14. Next Steps

- [ ] 설계 문서 업데이트 (Section 12 항목)
- [ ] 테스트 코드 작성 (Controller + System)
- [ ] 완료 보고서 작성 (`lot-tracking.report.md`)

---

## Related Documents

- Plan: [lot-tracking.plan.md](../01-plan/features/lot-tracking.plan.md)
- Design: [lot-tracking.design.md](../02-design/features/lot-tracking.design.md)
- Report: [lot-tracking.report.md](../04-report/features/lot-tracking.report.md) (미작성)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-12 | Initial gap analysis | Gap Detector Agent |
