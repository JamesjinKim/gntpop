# LOT 추적 (Lot Tracking) Design Document

> **요약**: LOT 번호 기반 생산 이력 추적 및 조회 기능의 기술 설계서
>
> **프로젝트**: GnT POP (생산시점관리 시스템)
> **버전**: 0.1.0
> **작성자**: GnT Dev Team
> **작성일**: 2026-02-12
> **상태**: Draft
> **Plan 문서**: [lot-tracking.plan.md](../../01-plan/features/lot-tracking.plan.md)

---

## 1. 개요

### 1.1 설계 목표

- LOT 번호 검색 전용 화면을 독립 컨트롤러로 구현 (SRP 준수)
- 단일 쿼리로 LOT의 전체 이력 조회 (eager loading으로 N+1 방지)
- 기존 production-tracking 기능에 영향 없는 추가 기능으로 구현
- 터치스크린 최적화 UI (공장 현장 사용)

### 1.2 설계 원칙

- **SRP**: LOT 추적 전용 컨트롤러 분리 (ProductionResultsController와 독립)
- **Rails Convention**: RESTful 라우팅, 네임스페이스 유지
- **DRY**: 기존 모델/관계를 그대로 활용, 새 모델 생성 없음
- **Fat Model, Skinny Controller**: 조회 로직은 모델 스코프 활용

---

## 2. 아키텍처

### 2.1 컴포넌트 다이어그램

```
┌──────────────────────────────────────────────────────────┐
│                     Browser (Hotwire)                     │
│  LOT 검색 폼 → Turbo Drive 요청 → 결과 페이지 렌더링      │
└────────────────────────┬─────────────────────────────────┘
                         │ GET /productions/lot_tracking?lot_no=...
                         │ GET /productions/lot_tracking/:lot_no
┌────────────────────────┴─────────────────────────────────┐
│              Productions::LotTrackingController            │
│                                                           │
│  index: LOT 검색 폼 + 검색 결과 리다이렉트                  │
│  show:  LOT 상세 이력 조회                                 │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ ProductionResult (기존 모델)                         │  │
│  │   .includes(:work_order => :product,                │  │
│  │             :manufacturing_process,                 │  │
│  │             :equipment,                             │  │
│  │             :worker,                                │  │
│  │             :defect_records => :defect_code)        │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

### 2.2 데이터 흐름

```
[LOT 검색]
  사용자 → index 화면에서 LOT 번호 입력
       → form submit (GET /productions/lot_tracking?lot_no=L-20260211-CVT-001-001)
       → 컨트롤러가 lot_no 파라미터로 ProductionResult 조회
       → 결과 있음: show 액션으로 리다이렉트
       → 결과 없음: index에 "미발견" 메시지 표시

[LOT 상세 조회]
  GET /productions/lot_tracking/:lot_no
       → ProductionResult.includes(...).find_by!(lot_no: lot_no)
       → show 뷰에 전체 이력 렌더링
```

---

## 3. 라우팅 설계

### 3.1 라우트 구조

```ruby
# config/routes.rb (추가분)
namespace :productions do
  # 기존 라우트 유지
  resources :work_orders do ...end
  resources :production_results

  # LOT 추적 (신규)
  resources :lot_tracking, only: [:index, :show], param: :lot_no
end
```

### 3.2 URL 패턴

| Method | URL | Controller#Action | 설명 |
|--------|-----|-------------------|------|
| GET | /productions/lot_tracking | lot_tracking#index | LOT 검색 화면 |
| GET | /productions/lot_tracking/:lot_no | lot_tracking#show | LOT 상세 이력 |

---

## 4. 컨트롤러 설계

### 4.1 Productions::LotTrackingController

```ruby
# app/controllers/productions/lot_tracking_controller.rb
class Productions::LotTrackingController < ApplicationController
  # LOT 검색 화면
  # GET /productions/lot_tracking
  # GET /productions/lot_tracking?lot_no=L-20260211-CVT-001-001
  def index
    if params[:lot_no].present?
      @production_result = find_by_lot_no(params[:lot_no].strip)

      if @production_result
        redirect_to productions_lot_tracking_path(lot_no: @production_result.lot_no)
      else
        @lot_no = params[:lot_no]
        @not_found = true
      end
    end
  end

  # LOT 상세 이력
  # GET /productions/lot_tracking/:lot_no
  def show
    @production_result = find_by_lot_no(params[:lot_no])
    @defect_records = @production_result.defect_records.includes(:defect_code)

    rescue ActiveRecord::RecordNotFound
      redirect_to productions_lot_tracking_index_path, alert: "LOT 번호를 찾을 수 없습니다."
  end

  private

  def find_by_lot_no(lot_no)
    ProductionResult
      .includes(
        work_order: :product,
        manufacturing_process: {},
        equipment: {},
        worker: {},
        defect_records: :defect_code
      )
      .find_by(lot_no: lot_no)
  end
end
```

---

## 5. UI/UX 설계

### 5.1 화면 목록

| 화면 | URL | 설명 |
|------|-----|------|
| LOT 검색 | /productions/lot_tracking | 검색 폼 + 미발견 메시지 |
| LOT 상세 이력 | /productions/lot_tracking/:lot_no | 전체 이력 대시보드 |

### 5.2 LOT 검색 화면 (index)

```
┌─────────────────────────────────────────────────┐
│  LOT 추적                                        │
├─────────────────────────────────────────────────┤
│                                                  │
│  LOT 번호로 생산 이력을 조회합니다.                   │
│                                                  │
│  ┌──────────────────────────────┐  ┌─────────┐  │
│  │ L-20260211-CVT-001-001      │  │  검색   │  │
│  └──────────────────────────────┘  └─────────┘  │
│                                                  │
│  (미발견 시)                                      │
│  ┌──────────────────────────────────────────┐   │
│  │ ⚠ "L-XXXXX" 에 해당하는 LOT을 찾을 수    │   │
│  │   없습니다.                               │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  최근 생산 LOT                                    │
│  ┌────────────────────────────────────────────┐  │
│  │ LOT 번호          │ 제품    │ 일시  │ 수량 │  │
│  │ L-20260211-CVT-.. │ OBC+.. │ 02-11 │  100 │  │
│  │ L-20260211-CVT-.. │ OBC+.. │ 02-11 │   80 │  │
│  └────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### 5.3 LOT 상세 이력 화면 (show)

```
┌─────────────────────────────────────────────────┐
│  LOT 추적 > L-20260211-CVT-001-001     [← 돌아가기]│
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌─────── LOT 기본 정보 ─────────────────────┐   │
│  │ LOT 번호:  L-20260211-CVT-001-001         │   │
│  │ 등록일시:  2026-02-11 14:30               │   │
│  │ 양품:  100개    불량:  5개    불량률: 4.76% │   │
│  └───────────────────────────────────────────┘   │
│                                                  │
│  ┌─────── 작업지시 정보 ─────────────────────┐   │
│  │ 작업지시코드: WO-20260211-001              │   │
│  │ 제품: CVT-001 / OBC+LDC 통합 컨버터        │   │
│  │ 지시수량: 500개   상태: 진행중              │   │
│  │ 계획일: 2026-02-11                        │   │
│  └───────────────────────────────────────────┘   │
│                                                  │
│  ┌─────── 공정/설비/작업자 ──────────────────┐   │
│  │ 공정:  [P020] 권선                        │   │
│  │ 설비:  [EQ-WND-01] 권선기 #1  (A동 2라인)  │   │
│  │ 작업자: [GNT-002] 이영희                   │   │
│  └───────────────────────────────────────────┘   │
│                                                  │
│  ┌─────── 작업 시간 ────────────────────────┐   │
│  │ 시작: 2026-02-11 12:30                    │   │
│  │ 종료: 2026-02-11 13:30                    │   │
│  │ 소요: 1시간 0분                            │   │
│  │ ●━━━━━━━━━━━━━━━━━━━━━━━● (타임라인)     │   │
│  │ 12:30                              13:30  │   │
│  └───────────────────────────────────────────┘   │
│                                                  │
│  ┌─────── 불량 기록 ────────────────────────┐   │
│  │ 불량코드    │ 유형       │ 수량 │ 설명    │   │
│  │ D04        │ 크랙       │  3  │ 코어 크랙│   │
│  │ D09        │ 외관불량   │  2  │ 스크래치 │   │
│  │─────────────────────────────────────────│   │
│  │ 합계                    │  5  │         │   │
│  └───────────────────────────────────────────┘   │
│                                                  │
└─────────────────────────────────────────────────┘
```

### 5.4 뷰 Partial 구조

```
app/views/productions/lot_tracking/
├── index.html.erb          # 검색 화면 (검색폼 + 최근 LOT 목록)
└── show.html.erb           # LOT 상세 이력 (정보 카드 4개 + 불량 테이블)
```

---

## 6. 에러 처리

| 상황 | 처리 | 사용자 표시 |
|------|------|------------|
| LOT 번호 미입력 | index 화면 유지 | 검색 폼만 표시 |
| LOT 미발견 (index 검색) | index에 @not_found 플래그 | "해당 LOT을 찾을 수 없습니다" 경고 메시지 |
| LOT 미발견 (show 직접 접근) | redirect_to index + flash[:alert] | "LOT 번호를 찾을 수 없습니다" |
| 인증 미완료 | Authentication concern | 로그인 페이지로 리다이렉트 |

---

## 7. 보안 고려사항

- [x] Authentication concern 적용 (ApplicationController 상속)
- [x] LOT 번호 파라미터 strip 처리 (공백 제거)
- [x] SQL Injection 방어 (ActiveRecord find_by 사용)
- [x] show 액션에서 존재하지 않는 LOT 접근 시 안전한 리다이렉트

---

## 8. 구현 순서

### 8.1 파일 구조

```
app/
├── controllers/
│   └── productions/
│       └── lot_tracking_controller.rb     # (신규)
├── views/
│   └── productions/
│       └── lot_tracking/
│           ├── index.html.erb             # (신규) 검색 화면
│           └── show.html.erb              # (신규) LOT 상세 이력
├── config/
│   └── routes.rb                          # (수정) lot_tracking 라우트 추가
└── views/layouts/
    └── _sidebar.html.erb                  # (수정) LOT 추적 링크 변경
```

### 8.2 구현 순서 (의존성 기반)

| 단계 | 작업 | 파일 | 의존성 |
|------|------|------|--------|
| **Step 1** | 라우트 추가 | config/routes.rb | 없음 |
| **Step 2** | 컨트롤러 생성 | app/controllers/productions/lot_tracking_controller.rb | Step 1 |
| **Step 3** | 검색 화면 (index) | app/views/productions/lot_tracking/index.html.erb | Step 2 |
| **Step 4** | 상세 이력 화면 (show) | app/views/productions/lot_tracking/show.html.erb | Step 2 |
| **Step 5** | 사이드바 링크 변경 | app/views/layouts/_sidebar.html.erb | Step 1 |

---

## 버전 이력

| 버전 | 날짜 | 변경 사항 | 작성자 |
|------|------|----------|--------|
| 0.1 | 2026-02-12 | 초안 작성 | GnT Dev Team |
