# 모니터링 (Monitoring) Planning Document

> **요약**: 생산현황판(대형 디스플레이용 실시간 현황) + 설비상태(설비 현황 대시보드) 2개 기능 구현
>
> **프로젝트**: GnT POP (생산시점관리 시스템)
> **버전**: 0.1.0
> **작성자**: GnT Dev Team
> **작성일**: 2026-02-12
> **상태**: Draft

---

## 1. 개요

### 1.1 목적

GnT POP 시스템의 모니터링 모듈(모듈 D)을 구현합니다. 사이드바의 모니터링 섹션 하위 2개 메뉴(생산현황판, 설비상태)를 실제 기능으로 연결합니다.

- **생산현황판**: 공장 현장의 대형 모니터에 표시할 실시간 생산 현황 화면 (전체화면 전용 레이아웃)
- **설비상태**: 설비별 가동 상태, 위치, 최근 생산 이력을 한눈에 파악하는 대시보드

### 1.2 배경

- GNT_POP_PLAN.md의 모니터링 섹션에 해당하는 기능
- 사이드바에 생산현황판, 설비상태 메뉴가 `#` 링크로 존재하나 미구현
- 컨버터/변압기 제조 현장에서 실시간 모니터링은 생산성 관리의 핵심
- DashboardQueryService에 이미 KPI, 공정별, 설비별 데이터 조회 메서드 구현됨

### 1.3 관련 문서

- 요구사항: `GNT_POP_PLAN.md` - 모듈 D: 모니터링
- 기존 구현: DashboardQueryService (KPI, 공정별, 설비별 집계)
- 기존 모델: Equipment (상태: idle/run/down/pm), WorkOrder (상태), ProductionResult

---

## 2. 범위

### 2.1 포함 범위 (In Scope)

#### 2.1.1 생산현황판 (Production Dashboard / Andon Board)
- [ ] 전체화면(Full Screen) 전용 레이아웃 (사이드바/헤더 없음)
- [ ] 날짜/시간 실시간 표시
- [ ] KPI 요약 카드: 금일 생산량, 달성률, 불량률, 설비가동률
- [ ] 공정별 진행 현황 테이블 (공정명, 목표, 실적, 달성률, 상태 표시등)
- [ ] 최근 생산실적 피드 (최근 5~10건)
- [ ] 자동 새로고침 (Turbo Frame 또는 meta refresh, 30초 간격)

#### 2.1.2 설비상태 (Equipment Status)
- [ ] 전체 설비 상태 요약 카드 (가동/대기/고장/정비 수)
- [ ] 설비별 상태 카드 그리드 (카드 형태로 배치)
- [ ] 설비 카드: 설비명, 공정, 위치, 현재 상태 배지, 최근 생산 LOT
- [ ] 상태별 필터 (전체/가동/대기/고장/정비)
- [ ] 상태 변경 기능 (인라인 버튼으로 가동/대기/고장/정비 전환)

### 2.2 제외 범위 (Out of Scope)

- WebSocket 기반 실시간 Push 업데이트 (Phase 6 이후, Action Cable 활용)
- 설비 IoT 센서 데이터 연동 (Phase 7)
- 설비 가동 이력 로그 테이블 (equipment_logs)
- OEE (Overall Equipment Effectiveness) 자동 계산
- 알람/경보 시스템 (SMS, 메일 알림)

---

## 3. 요구사항

### 3.1 기능 요구사항

#### 생산현황판

| ID | 요구사항 | 우선순위 | 상태 |
|----|----------|----------|------|
| FR-01 | 전체화면 전용 레이아웃 (사이드바/헤더 숨김) | High | Pending |
| FR-02 | KPI 요약 카드 4종 (생산량, 달성률, 불량률, 가동률) | High | Pending |
| FR-03 | 공정별 진행 현황 테이블 (프로그레스 바 포함) | High | Pending |
| FR-04 | 최근 생산실적 피드 (실시간 느낌) | Medium | Pending |
| FR-05 | 자동 새로고침 (30초 간격, Turbo Frame 또는 meta refresh) | Medium | Pending |
| FR-06 | 현재 날짜/시간 표시 | Low | Pending |
| FR-07 | 전체화면 진입/종료 버튼 | Low | Pending |

#### 설비상태

| ID | 요구사항 | 우선순위 | 상태 |
|----|----------|----------|------|
| FR-08 | 설비 상태 요약 카드 (가동/대기/고장/정비 수) | High | Pending |
| FR-09 | 설비별 상태 카드 그리드 | High | Pending |
| FR-10 | 상태별 필터 기능 (전체/가동/대기/고장/정비) | High | Pending |
| FR-11 | 설비 상태 변경 기능 (PATCH 요청) | High | Pending |
| FR-12 | 설비 카드에 공정명, 위치, 최근 LOT 표시 | Medium | Pending |
| FR-13 | 상태별 색상 코딩 (가동=초록, 대기=회색, 고장=빨강, 정비=노랑) | Medium | Pending |

### 3.2 비기능 요구사항

| 카테고리 | 기준 | 측정 방법 |
|----------|------|-----------|
| 성능 | 생산현황판 페이지 로딩 < 500ms | Rails 로그 측정 |
| 성능 | 설비상태 페이지 로딩 < 300ms | Rails 로그 측정 |
| 사용성 | 생산현황판은 대형 모니터 (1920x1080) 최적화 | UI 검증 |
| 사용성 | 터치스크린 최적화 (최소 44px 터치 타겟) | UI 검증 |
| 보안 | 인증된 사용자만 접근 가능 | Authentication concern |

---

## 4. 성공 기준

### 4.1 완료 조건 (Definition of Done)

- [ ] 생산현황판 전체화면 레이아웃으로 표시
- [ ] KPI 카드 4종이 실제 DB 데이터로 표시
- [ ] 공정별 진행 현황이 프로그레스 바로 시각화
- [ ] 자동 새로고침 동작 확인
- [ ] 설비 상태 카드가 전체 설비를 그리드로 표시
- [ ] 설비 상태 필터 및 변경 기능 동작
- [ ] 사이드바 2개 메뉴가 실제 화면으로 연결
- [ ] 기존 기능 회귀 없음

### 4.2 품질 기준

- [ ] N+1 쿼리 없음 (eager loading 적용)
- [ ] Service Object 활용 (기존 DashboardQueryService 확장/재활용)
- [ ] 반응형 레이아웃 (모바일/데스크톱/대형 모니터)

---

## 5. 리스크 및 대응

| 리스크 | 영향 | 발생 가능성 | 대응 방안 |
|--------|------|------------|----------|
| 자동 새로고침 시 Turbo 충돌 | Medium | Medium | meta refresh 또는 Stimulus controller로 구현 |
| 전체화면 레이아웃 전환 | Low | Low | 별도 layout 파일 사용 |
| 설비 상태 변경 권한 | Medium | Low | 현재는 모든 인증 사용자, 향후 RBAC 추가 |
| 대형 모니터 해상도 최적화 | Medium | Medium | 그리드 기반 레이아웃, 큰 폰트 사용 |

---

## 6. 아키텍처 고려사항

### 6.1 프로젝트 레벨

| 레벨 | 특성 | 선택 |
|------|------|:----:|
| **Dynamic** | 기능 기반 모듈, Service Objects | **V** |

### 6.2 주요 아키텍처 결정

| 결정 사항 | 옵션 | 선택 | 근거 |
|----------|------|------|------|
| 네임스페이스 | A) monitoring/ | monitoring/ | 사이드바 섹션명과 일치 |
| 자동 새로고침 | A) Turbo Frame / B) meta refresh / C) Stimulus timer | C) Stimulus | Turbo와 자연스럽게 통합, 세밀한 제어 가능 |
| 전체화면 레이아웃 | A) 별도 layout / B) 조건부 렌더링 | A) 별도 layout | 사이드바/헤더 완전 제거로 깔끔한 구현 |
| 설비 상태 변경 | A) 별도 edit 페이지 / B) 인라인 PATCH | B) 인라인 PATCH | 빠른 조작, 현장 터치스크린에 적합 |
| 서비스 재활용 | A) 새 서비스 / B) DashboardQueryService 확장 | B) 확장 + 전용 서비스 | 기존 KPI 로직 재활용, 전용 로직은 새 서비스 |

### 6.3 구현 구조

```
app/
├── controllers/
│   └── monitoring/
│       ├── production_board_controller.rb   # (신규) 생산현황판
│       └── equipment_status_controller.rb   # (신규) 설비상태
├── services/
│   ├── dashboard_query_service.rb           # (기존) KPI/공정/설비 집계 재활용
│   └── equipment_status_service.rb          # (신규) 설비 상태 집계/필터
├── views/
│   ├── monitoring/
│   │   ├── production_board/
│   │   │   └── index.html.erb              # (신규) 생산현황판
│   │   └── equipment_status/
│   │       └── index.html.erb              # (신규) 설비상태
│   └── layouts/
│       └── fullscreen.html.erb             # (신규) 전체화면 레이아웃
├── javascript/controllers/
│   ├── auto_refresh_controller.js          # (신규) 자동 새로고침 Stimulus
│   └── clock_controller.js                 # (신규) 실시간 시계 Stimulus
└── config/
    └── routes.rb                           # (수정) monitoring 네임스페이스 추가
```

### 6.4 라우트 설계

```ruby
namespace :monitoring do
  get "production_board", to: "production_board#index"
  resources :equipment_status, only: [:index] do
    member do
      patch :change_status  # 설비 상태 변경
    end
  end
end
```

---

## 7. 구현 순서

### Step 1: 라우트 및 컨트롤러 기반
1. `monitoring` 네임스페이스 라우트 추가
2. `Monitoring::ProductionBoardController` 생성
3. `Monitoring::EquipmentStatusController` 생성
4. 사이드바 메뉴 링크 연결

### Step 2: 생산현황판 (Production Board)
1. 전체화면 레이아웃 (`layouts/fullscreen.html.erb`) 생성
2. `auto_refresh_controller.js` Stimulus 컨트롤러 생성
3. `clock_controller.js` Stimulus 컨트롤러 생성
4. KPI 카드 4종 (DashboardQueryService 재활용)
5. 공정별 진행 현황 테이블 (프로그레스 바)
6. 최근 생산실적 피드
7. 자동 새로고침 연동

### Step 3: 설비상태 (Equipment Status)
1. `EquipmentStatusService` 생성 (요약, 필터, 최근 LOT)
2. 설비 상태 요약 카드 (가동/대기/고장/정비 수)
3. 설비별 카드 그리드 (상태 배지, 공정, 위치, 최근 LOT)
4. 상태별 필터 (링크 또는 탭 UI)
5. 설비 상태 변경 기능 (button_to PATCH, Turbo)

---

## 8. 의존성

### 8.1 기존 기능 의존성

| 의존 기능 | 용도 | 상태 |
|----------|------|------|
| DashboardQueryService | KPI, 공정별, 설비별 데이터 | 구현 완료 |
| Equipment 모델 | 설비 상태 enum, 공정 연관 | 구현 완료 |
| WorkOrder 모델 | 작업지시 상태/수량 | 구현 완료 |
| ProductionResult 모델 | 생산실적 데이터 | 구현 완료 |
| ManufacturingProcess 모델 | 공정별 진행 현황 | 구현 완료 |
| Chartkick + Chart.js | 차트 (importmap 설정 완료) | 구현 완료 |

### 8.2 신규 의존성

| 항목 | 용도 | 비고 |
|------|------|------|
| Stimulus controller (2개) | 자동 새로고침, 시계 | 추가 gem 불필요 |
| fullscreen layout | 생산현황판 전용 | 기존 layout 참조하여 생성 |

---

## 9. 다음 단계

1. [ ] Design 문서 작성 (`monitoring.design.md`)
2. [ ] 구현 시작

---

## 버전 이력

| 버전 | 날짜 | 변경 사항 | 작성자 |
|------|------|----------|--------|
| 0.1 | 2026-02-12 | 초안 작성 | GnT Dev Team |
