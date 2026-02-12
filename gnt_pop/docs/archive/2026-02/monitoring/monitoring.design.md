# 모니터링 (Monitoring) Design Document

> **요약**: 생산현황판(전체화면 Andon Board) + 설비상태(설비 대시보드) 2개 화면의 기술 설계서
>
> **프로젝트**: GnT POP (생산시점관리 시스템)
> **버전**: 0.1.0
> **작성자**: GnT Dev Team
> **작성일**: 2026-02-12
> **상태**: Draft
> **Plan 문서**: [monitoring.plan.md](../../01-plan/features/monitoring.plan.md)

---

## 1. 개요

### 1.1 설계 목표

- `monitoring/` 네임스페이스로 2개 컨트롤러 구현 (ProductionBoard, EquipmentStatus)
- 생산현황판: 전체화면 전용 레이아웃으로 공장 현장 대형 모니터에 최적화
- 설비상태: 카드 그리드 형태로 설비 현황 한눈에 파악 + 인라인 상태 변경
- Stimulus 컨트롤러로 자동 새로고침(30초)과 실시간 시계 구현
- 기존 DashboardQueryService의 KPI/공정/설비 집계 메서드 재활용

### 1.2 설계 원칙

- **SRP**: 생산현황판과 설비상태를 각각 독립 컨트롤러로 분리
- **DRY**: 기존 DashboardQueryService 재활용, EquipmentStatusService는 설비 전용 로직만 담당
- **Fat Model, Skinny Controller**: 집계 로직은 Service Object로 분리
- **Rails Convention**: RESTful 라우팅, namespace 구조
- **Static Tailwind Classes**: Tailwind CSS v4 호환을 위해 동적 보간 금지, case/when으로 정적 클래스 사용

---

## 2. 아키텍처

### 2.1 컴포넌트 다이어그램

```
┌────────────────────────────────────────────────────────────┐
│                     Browser (Hotwire)                       │
│  생산현황판 (전체화면) / 설비상태 (카드 그리드)              │
│  Stimulus: auto_refresh, clock                              │
└─────────────────────────┬──────────────────────────────────┘
                          │
┌─────────────────────────┴──────────────────────────────────┐
│                  monitoring/ Namespace                       │
│                                                             │
│  ┌─────────────────────────┐  ┌──────────────────────────┐ │
│  │ ProductionBoardCtrl     │  │ EquipmentStatusCtrl      │ │
│  │ layout: "fullscreen"    │  │ layout: "application"    │ │
│  │ #index                  │  │ #index, #change_status   │ │
│  │                         │  │                          │ │
│  │  ┌───────────────────┐  │  │  ┌────────────────────┐  │ │
│  │  │DashboardQuery     │  │  │  │EquipmentStatus     │  │ │
│  │  │Service (기존)     │  │  │  │Service (신규)      │  │ │
│  │  │- kpi_data         │  │  │  │- summary           │  │ │
│  │  │- process_data     │  │  │  │- filtered_list     │  │ │
│  │  │- recent_results   │  │  │  │- recent_lot        │  │ │
│  │  └───────────────────┘  │  │  └────────────────────┘  │ │
│  └─────────────────────────┘  └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────┴──────────────────────────────────┐
│                     Models (기존)                            │
│  Equipment / ManufacturingProcess / WorkOrder /              │
│  ProductionResult / Product                                  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 데이터 흐름

```
[생산현황판]
  사용자 → /monitoring/production_board (GET)
       → ProductionBoardController#index
       → DashboardQueryService.new(date: Date.current)
       → kpi_data, process_data, recent_results 조회
       → fullscreen 레이아웃으로 렌더링
       → Stimulus auto_refresh_controller: 30초마다 Turbo.visit(현재URL)
       → Stimulus clock_controller: 매초 시간 업데이트

[설비상태]
  사용자 → /monitoring/equipment_status (GET)
       → EquipmentStatusController#index
       → EquipmentStatusService.new.summary → 상태별 수
       → EquipmentStatusService.new.filtered_list(status:) → 설비 목록
       → application 레이아웃으로 렌더링

[설비 상태 변경]
  사용자 → 설비 카드에서 상태 버튼 클릭
       → PATCH /monitoring/equipment_status/:id/change_status
       → EquipmentStatusController#change_status
       → Equipment.find(id).update!(status: params[:status])
       → redirect_to 설비상태 페이지 (flash 메시지)
```

---

## 3. 라우트 설계

### 3.1 라우트 정의

```ruby
# config/routes.rb
namespace :monitoring do
  get "production_board", to: "production_board#index"
  resources :equipment_status, only: [:index] do
    member do
      patch :change_status
    end
  end
end
```

### 3.2 URL 매핑

| HTTP | URL | Controller#Action | 용도 |
|------|-----|-------------------|------|
| GET | `/monitoring/production_board` | `monitoring/production_board#index` | 생산현황판 |
| GET | `/monitoring/equipment_status` | `monitoring/equipment_status#index` | 설비상태 목록 |
| PATCH | `/monitoring/equipment_status/:id/change_status` | `monitoring/equipment_status#change_status` | 설비 상태 변경 |

---

## 4. 컨트롤러 설계

### 4.1 Monitoring::ProductionBoardController

```ruby
# app/controllers/monitoring/production_board_controller.rb
class Monitoring::ProductionBoardController < ApplicationController
  layout "fullscreen"

  def index
    service = DashboardQueryService.new(date: Date.current)
    @kpi = service.kpi_data
    @processes = service.process_data
    @recent_results = service.recent_results(limit: 10)
  end
end
```

**설계 포인트**:
- `layout "fullscreen"`: 사이드바/헤더 없는 전체화면 전용 레이아웃
- DashboardQueryService를 그대로 재활용하여 KPI, 공정, 최근실적 데이터 조회
- `recent_results(limit: 10)`: 현황판에는 10건 표시 (대시보드는 5건)

### 4.2 Monitoring::EquipmentStatusController

```ruby
# app/controllers/monitoring/equipment_status_controller.rb
class Monitoring::EquipmentStatusController < ApplicationController
  def index
    service = EquipmentStatusService.new
    @summary = service.summary
    @equipments = service.filtered_list(status: params[:status])
    @current_filter = params[:status]
  end

  def change_status
    @equipment = Equipment.find(params[:id])
    if @equipment.update(status: params[:status])
      redirect_to monitoring_equipment_status_index_path(status: params[:filter]),
                  notice: "#{@equipment.equipment_name} 상태가 '#{@equipment.status_i18n}'(으)로 변경되었습니다."
    else
      redirect_to monitoring_equipment_status_index_path(status: params[:filter]),
                  alert: "상태 변경에 실패했습니다."
    end
  end
end
```

**설계 포인트**:
- `index`: EquipmentStatusService로 요약/목록 조회, 상태별 필터 파라미터 처리
- `change_status`: Equipment 모델 직접 update, Turbo 호환 redirect

---

## 5. 서비스 설계

### 5.1 EquipmentStatusService (신규)

```ruby
# app/services/equipment_status_service.rb
class EquipmentStatusService
  # 설비 상태별 수 요약
  # @return [Hash] { run: 3, idle: 2, down: 1, pm: 0, total: 6 }
  def summary
    active = Equipment.active
    {
      run: active.where(status: :run).count,
      idle: active.where(status: :idle).count,
      down: active.where(status: :down).count,
      pm: active.where(status: :pm).count,
      total: active.count
    }
  end

  # 상태별 필터링된 설비 목록
  # @param status [String, nil] 필터 상태 (nil이면 전체)
  # @return [Array<Equipment>] 설비 목록 (eager loaded)
  def filtered_list(status: nil)
    scope = Equipment.active.includes(:manufacturing_process)
    scope = scope.where(status: status) if status.present?
    scope.order(:equipment_name)
  end

  # 설비의 최근 생산 LOT 번호 조회
  # @param equipment [Equipment] 설비
  # @return [String, nil] 최근 LOT 번호 또는 nil
  def recent_lot(equipment)
    equipment.production_results
             .order(created_at: :desc)
             .limit(1)
             .pick(:lot_no)
  end
end
```

**설계 포인트**:
- `summary`: 단순 count 쿼리, 5개 키 반환
- `filtered_list`: `includes(:manufacturing_process)`로 N+1 방지, 상태 필터는 optional
- `recent_lot`: 개별 설비의 최근 LOT 조회 (카드에 표시)

### 5.2 DashboardQueryService 변경 없음

기존 메서드 그대로 사용:
- `kpi_data` → 생산현황판 KPI 카드
- `process_data` → 생산현황판 공정별 현황
- `recent_results(limit:)` → 생산현황판 최근 실적 피드

---

## 6. 뷰 설계

### 6.1 레이아웃: fullscreen.html.erb

```
┌──────────────────────────────────────────────────────────────────┐
│  [GnT POP 생산현황판]                   [2026-02-12 14:30:25]   │
│  ← 돌아가기                                [전체화면] [새로고침] │
├──────────────────────────────────────────────────────────────────┤
│                         <%= yield %>                             │
├──────────────────────────────────────────────────────────────────┤
│  GnT POP v1.0 | 30초마다 자동 새로고침 | 마지막 갱신: 14:30:25  │
└──────────────────────────────────────────────────────────────────┘
```

**파일**: `app/views/layouts/fullscreen.html.erb`

**구성 요소**:
- DOCTYPE, head 태그 (application.html.erb와 동일한 meta/css/js)
- `body` 클래스: `bg-slate-900 text-white` (어두운 테마, 공장 환경에 적합)
- 상단 바: 제목, 실시간 시계 (`clock_controller`), 돌아가기 링크, 전체화면/새로고침 버튼
- 메인 영역: `yield`
- 하단 바: 버전 정보, 자동 새로고침 상태 표시
- `auto_refresh_controller` Stimulus 연결: `data-controller="auto-refresh"`

### 6.2 생산현황판 뷰: production_board/index.html.erb

```
┌──────────────────────────────────────────────────────────────────┐
│  [KPI 카드 영역 - 4개 카드 가로 배치]                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │ 금일생산  │ │ 달성률   │ │ 불량률   │ │ 설비가동률│           │
│  │  245EA   │ │  82.3%   │ │  1.5%   │ │  75.0%   │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
├──────────────────────────────────────────────────────────────────┤
│  [공정별 진행 현황]                      [최근 생산실적 피드]    │
│  ┌──────────────────────────┐           ┌──────────────────┐    │
│  │ 절단  ████████░░  80%   │           │ WO-240212-001    │    │
│  │ 권선  ██████░░░░  60%   │           │ 절단 | 50EA      │    │
│  │ 조립  ████░░░░░░  40%   │           │ 14:25            │    │
│  │ 검사  ██░░░░░░░░  20%   │           │ ...              │    │
│  └──────────────────────────┘           └──────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

**구성 요소**:
1. **KPI 요약 카드 4종** (어두운 배경에 맞는 카드 디자인)
   - 금일 생산량: `@kpi[:production][:actual]` / `[:target]`
   - 달성률: `@kpi[:production][:rate]`%
   - 불량률: `@kpi[:defect][:rate]`%
   - 설비가동률: `@kpi[:equipment][:rate]`%

2. **공정별 진행 현황** (좌측 2/3)
   - `@processes.each`로 프로그레스 바 렌더링
   - 공정명, 실적/목표, 진행률(%), 상태 표시등(running=pulse)
   - 색상: 80%↑=emerald, 50%↑=amber, 나머지=red (기존 process_item 패턴 동일)

3. **최근 생산실적 피드** (우측 1/3)
   - `@recent_results.each`로 10건 표시
   - 작업지시코드, 공정명, 수량, 시각

### 6.3 설비상태 뷰: equipment_status/index.html.erb

```
┌──────────────────────────────────────────────────────────────────┐
│  설비상태                                                        │
├──────────────────────────────────────────────────────────────────┤
│  [상태 요약 카드]                                                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │ 가동 3대 │ │ 대기 2대 │ │ 고장 1대 │ │ 정비 0대 │           │
│  │   ●      │ │   ●      │ │   ●      │ │   ●      │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
├──────────────────────────────────────────────────────────────────┤
│  [필터] [전체] [가동] [대기] [고장] [정비]                       │
├──────────────────────────────────────────────────────────────────┤
│  [설비 카드 그리드 - 3열]                                        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            │
│  │ CUT-001      │ │ WIND-001     │ │ ASM-001      │            │
│  │ 절단기 1호   │ │ 권선기 1호   │ │ 조립기 1호   │            │
│  │ ● 가동      │ │ ● 대기       │ │ ● 고장       │            │
│  │ 절단 | A동   │ │ 권선 | B동   │ │ 조립 | C동   │            │
│  │ LOT: L-0212  │ │ LOT: -       │ │ LOT: L-0211  │            │
│  │ [대기][고장] │ │ [가동][고장] │ │ [가동][정비] │            │
│  └──────────────┘ └──────────────┘ └──────────────┘            │
└──────────────────────────────────────────────────────────────────┘
```

**구성 요소**:
1. **페이지 헤더**: "설비상태" 타이틀

2. **상태 요약 카드 4종** (가로 배치)
   - 가동(run): `@summary[:run]`대 - emerald 테마
   - 대기(idle): `@summary[:idle]`대 - slate 테마
   - 고장(down): `@summary[:down]`대 - red 테마
   - 정비(pm): `@summary[:pm]`대 - amber 테마

3. **상태별 필터 탭**
   - 전체 / 가동 / 대기 / 고장 / 정비 링크
   - 현재 필터에 active 스타일 (bg-gnt-red text-white)
   - 각 링크: `monitoring_equipment_status_index_path(status: "run")` 등
   - "전체": 파라미터 없이 기본 URL

4. **설비 카드 그리드** (grid-cols-1 sm:grid-cols-2 lg:grid-cols-3)
   - 각 카드 정보: 설비코드, 설비명, 상태 배지(색상 코딩), 공정명, 위치, 최근 LOT
   - 상태 변경 버튼: 현재 상태를 제외한 다른 상태로 변경하는 `button_to` (PATCH)
   - 상태별 색상: case/when으로 정적 클래스 (Tailwind v4 호환)

### 6.4 상태별 색상 코딩 (정적 클래스)

```ruby
# 카드 배경/보더 클래스
card_class = case equipment.status
when "run"  then "border-emerald-200 bg-emerald-50"
when "idle" then "border-slate-200 bg-slate-50"
when "down" then "border-red-200 bg-red-50"
when "pm"   then "border-amber-200 bg-amber-50"
else "border-slate-200 bg-slate-50"
end

# 상태 배지 클래스
badge_class = case equipment.status
when "run"  then "bg-emerald-100 text-emerald-800"
when "idle" then "bg-slate-100 text-slate-800"
when "down" then "bg-red-100 text-red-800"
when "pm"   then "bg-amber-100 text-amber-800"
else "bg-slate-100 text-slate-800"
end

# 상태 도트 클래스
dot_class = case equipment.status
when "run"  then "bg-emerald-500 animate-pulse"
when "idle" then "bg-slate-400"
when "down" then "bg-red-500 animate-pulse"
when "pm"   then "bg-amber-500"
else "bg-slate-400"
end
```

---

## 7. Stimulus 컨트롤러 설계

### 7.1 auto_refresh_controller.js

```javascript
// app/javascript/controllers/auto_refresh_controller.js
// 페이지 자동 새로고침 (기본 30초 간격)
//
// 사용법:
//   <div data-controller="auto-refresh" data-auto-refresh-interval-value="30000">
//
// Targets:
//   countdown - 남은 시간 표시 요소
//
// Values:
//   interval: 새로고침 간격 (ms, 기본 30000)

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 30000 } }
  static targets = ["countdown"]

  connect()    // setInterval 시작
  disconnect() // clearInterval 정리
  refresh()    // Turbo.visit(window.location.href, { action: "replace" })
  tick()       // countdown 업데이트
}
```

**설계 포인트**:
- `Turbo.visit` 사용으로 전체 페이지 새로고침 없이 콘텐츠 교체
- `interval` Value로 새로고침 간격 커스터마이즈 가능
- `countdown` Target으로 "다음 새로고침까지 N초" 표시
- `disconnect()`에서 반드시 `clearInterval`로 메모리 누수 방지

### 7.2 clock_controller.js

```javascript
// app/javascript/controllers/clock_controller.js
// 실시간 시계 표시
//
// 사용법:
//   <span data-controller="clock" data-clock-target="display"></span>
//
// Targets:
//   display - 시간 표시 요소 (textContent로 업데이트)

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]

  connect()    // setInterval(1000) 시작
  disconnect() // clearInterval 정리
  tick()       // display.textContent = 현재 시간 (YYYY-MM-DD HH:MM:SS)
}
```

**설계 포인트**:
- 1초마다 `textContent` 업데이트 (DOM 조작 최소화)
- 한국 시간 표시: `new Date().toLocaleString("ko-KR", options)`
- `disconnect()`에서 정리하여 SPA 전환 시 메모리 누수 방지

---

## 8. 레이아웃 설계

### 8.1 fullscreen.html.erb 상세

```erb
<!DOCTYPE html>
<html class="h-full">
  <head>
    <!-- application.html.erb와 동일한 meta/css/js -->
    <title><%= content_for(:title) || "생산현황판 | GnT POP" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="h-full bg-slate-900 text-white"
        data-controller="auto-refresh"
        data-auto-refresh-interval-value="30000">

    <!-- 상단 바 -->
    <header class="bg-slate-800 border-b border-slate-700 px-6 py-3
                    flex items-center justify-between">
      <div class="flex items-center space-x-4">
        <span class="text-lg font-bold text-gnt-red">GnT POP</span>
        <span class="text-slate-400">|</span>
        <span class="text-lg font-semibold">생산현황판</span>
      </div>
      <div class="flex items-center space-x-4">
        <span data-controller="clock">
          <span data-clock-target="display"
                class="text-sm font-mono text-slate-300"></span>
        </span>
        <%= link_to "돌아가기", root_path,
            class: "text-sm text-slate-400 hover:text-white" %>
      </div>
    </header>

    <!-- 메인 콘텐츠 -->
    <main class="p-6">
      <%= yield %>
    </main>

    <!-- 하단 바 -->
    <footer class="fixed bottom-0 inset-x-0 bg-slate-800 border-t border-slate-700
                    px-6 py-2 flex items-center justify-between text-xs text-slate-500">
      <span>GnT POP v1.0</span>
      <span>
        자동 새로고침: 30초 |
        남은 시간: <span data-auto-refresh-target="countdown">30</span>초
      </span>
    </footer>
  </body>
</html>
```

### 8.2 어두운 테마 색상 체계

| 용도 | 클래스 |
|------|--------|
| 배경 | `bg-slate-900` |
| 카드 배경 | `bg-slate-800` |
| 카드 보더 | `border-slate-700` |
| 주 텍스트 | `text-white` |
| 보조 텍스트 | `text-slate-400` |
| 강조 | `text-gnt-red` |
| KPI 숫자 | `text-4xl font-bold text-white` |

---

## 9. 사이드바 메뉴 연결

### 9.1 변경 내용

```erb
<!-- 기존 (# 링크) -->
<%= link_to "#", class: "..." do %>
  <span class="ml-3">생산현황판</span>
<% end %>

<!-- 변경 후 -->
<%= link_to monitoring_production_board_path, class: "..." do %>
  <span class="ml-3">생산현황판</span>
<% end %>

<%= link_to monitoring_equipment_status_index_path, class: "..." do %>
  <span class="ml-3">설비상태</span>
<% end %>
```

### 9.2 Active 상태 표시

```ruby
# 생산현황판
request.path.start_with?('/monitoring/production_board') ? 'bg-gray-800 text-white' : ''

# 설비상태
request.path.start_with?('/monitoring/equipment_status') ? 'bg-gray-800 text-white' : ''
```

---

## 10. 파일 목록

### 10.1 신규 파일

| 파일 | 용도 |
|------|------|
| `app/controllers/monitoring/production_board_controller.rb` | 생산현황판 컨트롤러 |
| `app/controllers/monitoring/equipment_status_controller.rb` | 설비상태 컨트롤러 |
| `app/services/equipment_status_service.rb` | 설비 상태 집계/필터 서비스 |
| `app/views/layouts/fullscreen.html.erb` | 전체화면 전용 레이아웃 |
| `app/views/monitoring/production_board/index.html.erb` | 생산현황판 뷰 |
| `app/views/monitoring/equipment_status/index.html.erb` | 설비상태 뷰 |
| `app/javascript/controllers/auto_refresh_controller.js` | 자동 새로고침 Stimulus |
| `app/javascript/controllers/clock_controller.js` | 실시간 시계 Stimulus |

### 10.2 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `config/routes.rb` | `namespace :monitoring` 블록 추가 |
| `app/views/layouts/_sidebar.html.erb` | 모니터링 메뉴 링크 연결 + active 상태 |

---

## 11. 구현 순서

### Step 1: 라우트 및 컨트롤러 기반
1. `config/routes.rb`에 `namespace :monitoring` 블록 추가
2. `app/controllers/monitoring/production_board_controller.rb` 생성
3. `app/controllers/monitoring/equipment_status_controller.rb` 생성
4. `app/views/layouts/_sidebar.html.erb` 메뉴 링크 연결

### Step 2: 생산현황판
1. `app/views/layouts/fullscreen.html.erb` 전체화면 레이아웃 생성
2. `app/javascript/controllers/auto_refresh_controller.js` 생성
3. `app/javascript/controllers/clock_controller.js` 생성
4. `app/views/monitoring/production_board/index.html.erb` 뷰 생성
   - KPI 카드 4종 (어두운 테마)
   - 공정별 진행 현황 (프로그레스 바)
   - 최근 생산실적 피드

### Step 3: 설비상태
1. `app/services/equipment_status_service.rb` 생성
2. `app/views/monitoring/equipment_status/index.html.erb` 뷰 생성
   - 상태 요약 카드 4종
   - 상태별 필터 탭
   - 설비 카드 그리드 (상태 배지, 공정, 위치, 최근 LOT)
   - 상태 변경 버튼 (button_to PATCH)

---

## 12. 비기능 요구사항 대응

### 12.1 성능

| 항목 | 대응 방안 |
|------|----------|
| 생산현황판 < 500ms | DashboardQueryService의 효율적인 쿼리 재활용 |
| 설비상태 < 300ms | `includes(:manufacturing_process)` eager loading |
| N+1 방지 | EquipmentStatusService에서 일괄 조회 |

### 12.2 사용성

| 항목 | 대응 방안 |
|------|----------|
| 대형 모니터 최적화 | `text-4xl` 이상 큰 폰트, 어두운 배경 |
| 터치스크린 | 최소 44px 터치 타겟, 큰 버튼 (`px-4 py-3`) |
| 가시성 | 상태별 색상 코딩, animate-pulse로 가동/고장 강조 |

### 12.3 보안

| 항목 | 대응 방안 |
|------|----------|
| 인증 | ApplicationController의 Authentication concern 상속 |
| CSRF | `button_to`는 Rails가 자동으로 CSRF 토큰 포함 |

---

## 13. 의존성

### 13.1 기존 의존성 (변경 없음)

| 항목 | 용도 |
|------|------|
| DashboardQueryService | 생산현황판 KPI/공정/실적 데이터 |
| Equipment 모델 | 설비 상태 enum, 공정 연관 |
| ManufacturingProcess 모델 | 공정별 진행 현황 |
| ProductionResult 모델 | 최근 실적, LOT 정보 |
| Stimulus (Hotwire) | auto_refresh, clock 컨트롤러 |

### 13.2 신규 의존성

추가 gem 없음. 모든 기능은 기존 스택(Rails 8 + Hotwire + Tailwind)으로 구현.

---

## 버전 이력

| 버전 | 날짜 | 변경 사항 | 작성자 |
|------|------|----------|--------|
| 0.1 | 2026-02-12 | 초안 작성 | GnT Dev Team |
