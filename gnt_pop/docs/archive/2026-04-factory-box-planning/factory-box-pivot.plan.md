# Factory Box Pivot — MES 공통 모듈 + WDAQ 연동 MVP Plan

> **요약**: GnT POP을 In-place 피벗하여 Factory Box Track 1(Mini MES + WDAQ 올인원) 의 **레퍼런스 구현(테넌트 #1 = GnT 내부)** 으로 전환하는 **3개월 MVP (P2)**.
>
> **프로젝트**: GnT POP → Factory Box Reference
> **버전**: 0.5.1 (레드팀 2차 조건부 승인 → 5개 최소 수정 반영)
> **작성자**: 신호테크놀로지 R&D (Claude 지원)
> **작성일**: 2026-04-19
> **기간**: 2026-04-20 ~ 2026-07-20 (3개월, 12주, P2)
> **상태**: **✅ 승인 완료** (레드팀 최종 검증 통과, 2026-04-19) — `/pdca design` 진입 가능
> **이전 버전**:
>  - v0.4.0 (1개월 P1) — 레드팀 1차 반려 (C1~C5 치명적 결함)
>  - v0.5.0 (3개월 P2) — 레드팀 2차 조건부 승인 (M1~M5 수정 요구)

---

## 0. 변경 이력

### v0.4.0 → v0.5.0 (레드팀 1차 반려 반영)

| 항목 | v0.4.0 | v0.5.0 | 반영 레드팀 지적 |
|-----|--------|--------|---------------|
| 기간 | 1개월 (P1) | **3개월 (P2)** | C3 (W1 일정 불가능) |
| FR-12/13 (δ AI 스켈레톤) | In Scope | **Out of Scope로 이동** | M3 |
| 테스트 커버리지 80% | 전범위 | **신규 코드만 80%, 레거시는 별도 Plan** | C2 |
| W1 | 멀티테넌시 전환 완료 | **스파이크 + 설계 + 롤백 드릴** | C3 |
| Open Issues 섹션 | 없음 | **§9 신설** | M1·M5·M6 등 |
| 롤백 플랜 | R8 한 줄 | **§10 신설** | C4 |
| Current.tenant 전파 | ApplicationController만 | **§6.6 신설** — Queue/Cable/Rake 4경로 | C5 |
| Kill-switch | "Weekly 리뷰" | **§5 R7 정량 기준** | M4 |
| 용어 hook 화이트리스트 | 없음 | **§3.3 레거시 경로 제외** | M7 |
| FR-01 관리자 권한 모델 | 누락 | **FR-01a/b/c 분해** | M8 |

### v0.5.0 → v0.5.1 (레드팀 2차 조건부 승인 — 5개 최소 수정 반영)

| ID | 항목 | v0.5.0 | v0.5.1 | 섹션 |
|----|-----|--------|--------|-----|
| **M1** | 운영 중단 SLA | "0분 보장" (자기모순) | **계획 중단 ≤ 10분 / 롤백 ≤ 15분 SLA** + Online migration 3단계 명시 | §3.2, §10.1~10.2 |
| **M2** | 승인 절차 | "서명일 __" (셀프 승인 리스크) | **G1~G5 게이트** 명문화, 레드팀 판정이 필수 조건 | §11.2 |
| **M3** | R11 Kill-switch | 주 진척 60% 3주 연속 | **3가지 OR 조건** (시간/진척/비-코딩시간) + 드롭 순서 변경(품질 드롭 금지) | §5 R11 |
| **M4** | 품질 항목 위치 | W11 1주 몰빵 | **W2부터 매주 분산** (PR/주간/게이트별 매트릭스) | §4.2, §7 |
| **M5** | OI-08 CI/CD | W2 종료 Gate | **W1 종료 Gate로 전진** (Spike 산출물에 포함) | §9 OI-08, §7 W1 |
| +레드팀 권고 | `legacy-test-backfill.plan.md` 스텁 | 미작성 | **W1 내 작성 DoD 포함** | §4.2.1 |
| +N7 반영 | 드롭 순서 | D(품질)→C γ→B | **C γ → B 시뮬레이터 → C β → D 절대 드롭 금지** | §5 R11 |

---

## 1. 개요

### 1.1 목적

현재 GnT 단일 고객용으로 동작하는 [gnt_pop](../../..) Rails 8 애플리케이션을, Factory Box 전략(v5)의 Track 1(Mini MES + WDAQ 올인원) 레퍼런스로 In-place 피벗한다.
3개월 MVP 기간 동안 다음 3가지를 **안전하게** 달성한다.

1. **멀티테넌시 Level 1** — `tenant_id` 스코핑. GnT 운영 SLA(§3.2: 계획 중단 ≤ 10분 / 롤백 ≤ 15분) 준수.
2. **WDAQ 시뮬레이터** — 실 하드웨어 없이 센서 데이터 end-to-end 흐름 검증.
3. **POP × WDAQ 상관 분석 α+β+γ** — 조회/차트/룰 경보까지. AI(δ)는 Out of Scope.

### 1.2 배경

| 항목 | 현황 |
|------|------|
| 모기업 | 신호테크놀로지 — 삼성디스플레이에 WDAQ(Edge AI 이상탐지) 납품 중 |
| 정부과제 | 2026-05~11 지역자율형 디지털혁신프로젝트, 산출물 = WDAQ Edge AI + Hailo-8L NPU |
| 시장 | 국내 중소제조업 163,273개 중 80.5%(131,000개) MES 미도입 → Track 1 타겟 |
| 현재 자산 | GnT POP (Rails 8 + Hotwire + **PostgreSQL**) — MES 표준 공통 모듈 구현 |
| 피벗 동기 | 대기업 기술(WDAQ) → 중소기업용 제품화(Factory Box) |

> ⚠️ **DB 어댑터 사실 확정**: `config/database.yml`·`schema.rb`는 **PostgreSQL**이다. CLAUDE.md와 메모리의 "SQLite" 기재는 과거 내용이므로 이번 Plan 진행과 함께 수정한다. (M1 반영)

### 1.3 전제와 제약 (사용자 확정 답변)

| 구분 | 내용 |
|------|------|
| Q1 리포 전략 | **A. In-place 피벗** |
| Q2 GnT 정체성 | **A. 내부 레퍼런스** (유료 고객 아님) |
| Q3 Track 우선순위 | **Track 1** |
| Q4 WDAQ 하드웨어 | **Y. 시뮬레이터** |
| Q5 GnT 특화 | **B. 유지** (enum/용어 그대로) |
| Q6 멀티테넌시 | **Level 1** (tenant_id + Row-level scoping) |
| Q7 기간 | **P2. 3개월** (v0.5.0 변경) |
| Q8 Plan 범위 | **개발 전용** |
| Q9 POP×WDAQ 분석 | **α+β+γ (δ는 Out of Scope)** |

### 1.4 관련 문서

- **상위 전략 문서**: [../factory-box-strategy.md](../factory-box-strategy.md) — 2026-04-19 커밋 (OI-01 해소)
- 기존 Plan: `./production-tracking.plan.md`, `./quality-management.plan.md`
- 아카이브: `../../archive/2026-02/monitoring/`, `../../archive/2026-02/lot-tracking/`
- 현행 ERD: `../../DB_ERD.md`

---

## 2. 범위

### 2.1 포함 범위 (In Scope)

#### A. 멀티테넌시 기반
- [ ] `Tenant` 모델 + 마이그레이션 + 시드(GnT 테넌트 id=1)
- [ ] `acts_as_tenant` vs 수동 스코핑 **결정 완료 후** 도입 (W1 스파이크 산출물)
- [ ] 9개 도메인 테이블 + `User` + `Session`에 `tenant_id` 추가
- [ ] 복합 unique: `(tenant_id, code)` 재설계
- [ ] `Current` 모델에 `tenant` 추가
- [ ] `ApplicationController` 훅 — 로그인 사용자 기반 tenant 설정
- [ ] **ActiveJob (Solid Queue) tenant 전파** — `around_perform` 콜백 (§6.6)
- [ ] **ActionCable 채널 tenant 전파** — `connection` 단위 식별 (§6.6)
- [ ] **Rake 태스크 tenant 전파** — `ENV["TENANT"]` 표준 (§6.6)
- [ ] tenant 격리 침투 테스트 (`tenant_isolation_test.rb`) — 타 테넌트 PK 접근 시 404

#### A'. 관리자 권한 모델 (FR-01 분해)
- [ ] **FR-01a**: `User.role` enum 도입 — `super_admin` / `tenant_admin` / `member`
- [ ] **FR-01b**: 슈퍼어드민만 Tenant CRUD 가능. 테넌트 어드민은 자신의 테넌트 내 User CRUD
- [ ] **FR-01c**: 로그인 후 테넌트 컨텍스트 표시 UI (헤더 뱃지)

#### B. WDAQ 시뮬레이터 & 브릿지
- [ ] `SensorReading` 모델 + 인덱스(`tenant_id, equipment_id, recorded_at`)
- [ ] **PG 파티셔닝 여부** = Open Issue OI-05 (§9). 초기는 단일 테이블로 시작, 부하테스트 후 결정
- [ ] 72h 롤링 cleanup — Solid Queue **recurring job** (`SensorReadingCleanupJob`)
- [ ] `POST /api/v1/sensor_readings` — 토큰 기반 인증 + tenant 식별 (토큰 스킴 = OI-06)
- [ ] `WdaqSimulator` Rake (`rake wdaq:simulate TENANT=gnt MODE=normal`)
  - 5종 센서 (vibration_rms, temperature, humidity, current, pressure)
  - 모드: `normal` / `anomaly` / `mixed`
  - 페이로드 스키마 = **정부과제 WDAQ 실제 스펙과 동기화** (OI-02)
- [ ] `LotSensorSnapshotService` TODO 3개 실구현
  - `collect_sensor_data` — SensorReading 기간 집계
  - `collect_safety_data` — 현재 활성 Alert 목록
  - `calculate_statistics` — count/avg/p95/max

#### C. POP × WDAQ 상관 분석 (Level α+β+γ)
- [ ] **Level α**: `Quality::CorrelationController#index` + `#show(lot_no)` — LOT 별 `production_results` + `defect_records` + `lot_sensor_snapshots` JOIN 표시
- [ ] **Level β**: LOT 상세 페이지 Chartkick 시계열 — 센서값 × 불량 마커. **서버 다운샘플링** 적용 (1000 포인트 상한, m4 반영)
- [ ] **Level γ**: 룰 엔진
  - `AlertRule` 모델 (tenant_id, sensor_type, operator, threshold_min/max, severity)
  - `RuleBasedAlertService` — 센서 수신 후 동기 판정 (< 100ms)
  - `Alert` 모델 + `AlertChannel` WebSocket 브로드캐스트
  - `Monitoring::AlertsController#index` — 실시간 알림 리스트 + acknowledge
  - 시드 룰 3~5개 (진동 > 2.0, 온도 > 80°C 등)

#### D. 운영/품질
- [ ] 시드 재정비 — GnT 테넌트 + "시범 고객 A" 테넌트 + 기본 알림 룰 + 24h 샘플 센서
- [ ] README "Factory Box 아키텍처" 섹션 + "3분 체험 가이드"
- [ ] CLAUDE.md 갱신 (SQLite → PG 정정, Factory Box 브랜치 안내)
- [ ] **용어 가이드 hook** — `.githooks/pre-commit` + 화이트리스트 (§3.3)
- [ ] Minitest — **신규 코드 커버리지 80%** (레거시 범위는 §4.2 재정의)
- [ ] Bullet(N+1 검출), Brakeman, Rubocop 그린

### 2.2 제외 범위 (Out of Scope)

| 제외 항목 | 이유 | 후속 |
|----------|-----|------|
| δ (AI Autoencoder) 스켈레톤 (구 FR-12/13) | M3 — 인터페이스 설계보다 실 스펙 수령 후 착수가 안전 | Phase 2, 정부과제 산출물 도입 시 |
| 실 WDAQ 하드웨어 / MQTT / InfluxDB | Q4 | Phase 2 |
| Track 2 (이카운트 연동) | Q3 | 2호 고객 확보 시 |
| Rails Engine 추출 | Q1 | 2호 고객 확보 시 |
| 스키마/DB 분리 멀티테넌시 | Q6 | 10+ 테넌트 시 |
| 영업/정부보조금/GTM | Q8 | `factory-box-gtm.md` 별도 |
| 업종별 커스텀 모듈 | 전략 §4 | 업종 1호 고객 시 |
| 모바일 2~3터치 UX | 별도 Plan | Phase 2 |
| 레거시 코드 전체 테스트 커버리지 80% 달성 | C2 — 비현실적 | 별도 Plan `legacy-test-backfill.plan.md` |

---

## 3. 요구사항

### 3.1 기능 요구사항

| ID | 요구사항 | 우선순위 | 레이어 |
|----|---------|--------|------|
| FR-01a | User.role enum (super/tenant_admin/member) | High | A' |
| FR-01b | Tenant CRUD (super_admin 전용) | High | A' |
| FR-01c | 현재 tenant 컨텍스트 표시 UI | Medium | A' |
| FR-02 | 로그인 시 tenant 컨텍스트 자동 설정 | High | A |
| FR-03 | 9개 도메인 테이블 tenant 스코핑 강제 | High | A |
| FR-04 | ActiveJob tenant 전파 (around_perform) | High | A |
| FR-05 | ActionCable connection tenant 식별 | High | A |
| FR-06 | Rake 태스크 ENV["TENANT"] 표준 | Medium | A |
| FR-07 | GnT + 시범 고객 A 시드 | High | A |
| FR-08 | WDAQ 시뮬레이터 Rake (5종 센서, 3모드) | High | B |
| FR-09 | SensorReading 수신 API + 72h 롤링 cleanup | High | B |
| FR-10 | LOT 시작/종료 센서 스냅샷 실구현 | High | B |
| FR-11 | LOT 상관 조회 화면 (α) | High | C |
| FR-12 | LOT 시계열 차트 + 다운샘플링 (β) | High | C |
| FR-13 | AlertRule CRUD + 룰 엔진 (γ) | High | C |
| FR-14 | 실시간 Alert WebSocket | Medium | C |
| FR-15 | 용어 가이드 pre-commit hook + 화이트리스트 | Medium | D |

### 3.2 비기능 요구사항

| 카테고리 | 기준 | 측정 방법 |
|---------|-----|--------|
| 격리성 | 테넌트 간 데이터 누출 0건 | `tenant_isolation_test.rb` (모델×컨트롤러×잡×채널×rake) |
| 성능 | 센서 API throughput ≥ 50 req/s, 레이턴시 p95 < 200ms | `wrk` 부하 테스트, 30분 지속 |
| 성능 | LOT 상관 조회 p95 < 1s (24h 데이터, 1000 포인트 다운샘플) | `rack-mini-profiler` 100 샘플 |
| 신뢰성 | 룰 엔진 판정 p95 < 100ms | 서비스 단위 벤치마크 |
| 확장성 | tenant_id 컬럼에 인덱스, `EXPLAIN ANALYZE`에 SeqScan 금지 | CI에 explain check |
| 보안 | 타 테넌트 PK 직접 접근 시 404 | 침투 테스트 케이스 10+ |
| **운영 안전** | **사전 공지 계획 중단 ≤ 10분 / 롤백 시 복구 ≤ 15분 (SLA)** | §10 online migration 절차, maintenance mode 사용 시 별도 공지 |

### 3.3 용어 가이드 (전략 §1)

UI/카피/커밋/신규 코드에서 아래 규칙을 지킨다. pre-commit hook은 **지정 경로만 검사**.

| ✅ 사용 | ❌ 금지 |
|-------|-------|
| 품질 사고 예방 | 예지보전, Predictive Maintenance |
| 공정 품질 관리 | 고장 예측 |
| 이상 조기 감지 | 설비 수명 연장 |
| 충돌 예방 | |

**Hook 검사 범위 (화이트리스트)**:
- ✅ 검사: `app/**/*.{rb,erb}`, `config/locales/**/*.yml`, `docs/01-plan/**`, `docs/02-design/**`, `README.md`
- ❌ 제외: `GNT_POP_PLAN.md`, `GNT_POP_MVP_PLAN.md`, `GNT_POP_VISION.md`, `docs/archive/**`, `factory-box-strategy.md` (구 표현이 역사적 기록으로 존재)

---

## 4. 성공 기준

### 4.1 완료 조건 (Definition of Done)

- [ ] FR-01~FR-15 구현 + 테스트 통과
- [ ] GnT + "시범 고객 A" 2개 테넌트 동시 운영 시 데이터 격리 자동 검증 그린
- [ ] 시뮬레이터 30분 부하 → 대시보드 실시간 반영 + 알림 1건 이상
- [ ] README "3분 체험" 가이드로 신규 개발자가 환경 구동 성공
- [ ] **레드팀 2차 검토 통과**
- [ ] **승인자 합의 서명** (승인자 = OI-03)

### 4.2 품질 기준 (신규 코드 한정, **매주 DoD로 분산 — M4 반영**)

| 품질 항목 | 검증 빈도 | 기준 | 누적 방식 |
|---------|---------|-----|---------|
| SimpleCov `--branch` 커버리지 | **PR마다** (자동) | 신규 diff 80% 이상 | CI 실패 시 머지 차단 |
| Rubocop | **PR마다** (자동) | 0 경고 | CI 실패 시 머지 차단 |
| Brakeman | **주 1회** (W2부터) | 0 경고 | 주간 점검, 발견 시 당주 수정 |
| Bullet (N+1) | **신규 컨트롤러 도입 시** | 0 알림 | dev 환경 + CI dry-run |
| 용어 가이드 hook | **커밋마다** (자동) | 화이트리스트 범위 위반 0 | pre-commit hook |
| 마이그레이션 역방향 | **마이그레이션 작성 시** | `db:rollback` 그린 | 커밋 전 로컬 검증 |
| tenant 격리 침투 테스트 | **W6부터 매주** | 실패율 ≤ 30% → 점진적 0%로 | 주간 누적 |
| 로드 테스트 (센서 API) | **W7, W8, W12** | NFR p95 기준 | 각 회차 리포트 |

> **W11 = 최종 점검만**: 위 품질 항목은 W2부터 매주 누적 관리. W11은 통합 회귀 + 누락 항목 클린업만 담당 (레드팀 2차 N6 지적 반영).

### 4.2.1 완료 조건 (신규 코드 한정 DoD)
- [ ] 모든 품질 항목이 **PR 단위로 그린** (12주 내내)
- [ ] 마이그레이션 역방향(`db:rollback`) 동작 검증 (모든 신규 마이그레이션)
- [ ] `legacy-test-backfill.plan.md` 스텁 파일이 W1 내 작성 (C2 참조 무결성, 레드팀 2차 권고)

### 4.3 Acceptance Demo

```
[시나리오 1] 멀티테넌시 격리
  - GnT vs 시범 고객 A 로그인 전환으로 각자 데이터만 노출
  - 타 테넌트 URL 직접 접근 404

[시나리오 2] 잡/채널/rake tenant 전파
  - wdaq:simulate TENANT=gnt 실행 → GnT 테넌트에만 SensorReading 적재
  - AlertChannel 구독 → 타 테넌트 Alert 수신 불가

[시나리오 3] POP × WDAQ 상관 분석
  - wdaq:simulate MODE=mixed 시작
  - 작업지시 → LOT 시작 → 센서 스냅샷 자동 기록
  - 진동 피크 구간에서 Alert 발생 + 불량 입력
  - LOT 상관 페이지에서 시각적 매칭 확인

[시나리오 4] 운영 안전 (롤백 드릴)
  - 신규 마이그레이션 전체 rollback → GnT 운영 정상
```

---

## 5. 리스크 및 대응 (Kill-switch 포함)

| # | 리스크 | 영향 | 가능성 | 대응 | **Kill-switch** |
|---|-------|-----|------|-----|----------------|
| R1 | tenant_id 마이그레이션이 GnT 데이터 손상 | High | Medium | §10 절차 + online migration + backfill 검증 스크립트 | W4 종료 시 GnT 회귀 테스트 미통과 → 피벗 중단, GnT 운영본 복귀 |
| R2 | ActsAsTenant/수동 스코핑 누락 쿼리 | High | High | `tenant_required!` 매크로 + CI lint, `Current.tenant=nil` 강제 예외 테스트 | W6 종료 시 격리 침투 테스트 30% 이상 실패 → 설계 재검토 |
| R3 | SensorReading 테이블 규모 증가로 성능 저하 | Medium | High | 72h recurring cleanup, 인덱스 3종, 필요 시 파티셔닝(OI-05) | W8 종료 시 NFR p95<1s 미달 → 파티셔닝 강제 도입 |
| R4 | 용어 가이드 위반 혼입 | Medium | Medium | pre-commit hook + 화이트리스트 | — |
| R5 | WDAQ 실 스펙(정부과제)과 시뮬레이터 페이로드 불일치 | Medium | High | OI-02 해소 전까지 시뮬레이터 스키마 변경 가능 상태 유지 | OI-02 미해소 시 WDAQ 스펙 합의 전까지 FR-09 freeze |
| R6 | Level 1 멀티테넌시가 20+ 테넌트에서 성능 한계 | Low | Low | 1~5 테넌트 수준에선 문제없음 | 10 테넌트 초과 시 Phase 2 Level 2 재설계 |
| **R7** | **Scope Creep** | **High** | **High** | Weekly 리뷰 + 아래 정량 Kill-switch | **W4 종료 시 A 레이어 완료율 < 70% → Plan Pause 전환 및 범위 재협상** |
| R8 | GnT 운영본과 피벗본 혼재로 사고 | High | Medium | §10 롤백 플랜, 브랜치 분리, 태그 `gnt-v1-final` | 운영 사고 1회 발생 → 즉시 롤백 + 원인 분석까지 작업 중단 |
| R9 | ActionCable tenant 전파 버그 | High | Medium | `Channel#subscribed` 단위 테스트 + 침투 테스트 | W6 침투 테스트에서 채널 누출 발견 시 C 레이어 freeze |
| R10 | 정부과제 산출물 지연으로 Phase 2 접점 모호 | Medium | High | Phase 2는 별도 Plan, 본 Plan은 δ Out of Scope | — |
| R11 | 단일 개발자(주 40h) + AI 페어링 병목 | High | Medium | **사용자 1인 + Claude 상시** 운영. AI가 커버 가능한 영역(테스트/문서/보일러플레이트) 위임, 의사결정·아키텍처는 사용자 주도. **주간 시간 로그(`docs/03-analysis/weekly-time-log.md`)에 actual vs 40h 계획 시간 기록**. Claude가 커버 불가한 작업(wrk 부하 테스트 실행, pg_dump 리허설, 정부과제 팀 미팅)은 "비-코딩 시간"으로 별도 집계 | **자동 발화 조건 (3가지 OR)**: ① 주당 actual < 계획의 80%가 **3주 연속** / ② 주당 진척(FR 완료율 기준) < 계획 60%가 **3주 연속** / ③ 비-코딩 시간이 주 15h 초과 **2주 연속**. 발화 시 범위 축소 순서: **(M4 반영) C γ 완전 드롭 → B 시뮬레이터 단순화(센서 3종으로 축소) → C β 차트 축소 → D 품질은 드롭 금지** |

---

## 6. 아키텍처 고려사항

### 6.1 프로젝트 레벨

Dynamic (Rails MVC + Service Objects + ActionCable)

### 6.2 주요 ADR

| 결정 | 선택 | 근거 | 확정 시점 |
|-----|-----|-----|---------|
| 멀티테넌시 레벨 | Level 1 (Discriminator) | Q6 | 확정 |
| Gem vs 수동 | **Spike 후 W1 말 확정** | 벤치마크 필요 | W1 종료 |
| 센서 저장소 | PG 단일 테이블 (파티셔닝은 OI-05) | 1개월 부하테스트 결과 반영 | 확정 |
| 시뮬레이터 | Rake task | 개발/데모 편의 | 확정 |
| 룰 엔진 | DB 기반 (`AlertRule`) | 룰 추가에 코드 변경 불필요 | 확정 |
| 브랜치 전략 | `factory-box-pivot` 브랜치 + `gnt-v1-final` 태그 | C4/R8 | 확정 |

### 6.3 디렉토리 구조 (추가)

```
app/
├── controllers/
│   ├── tenants_controller.rb
│   ├── monitoring/alerts_controller.rb
│   └── quality/correlation_controller.rb
├── models/
│   ├── tenant.rb, current.rb
│   ├── sensor_reading.rb
│   ├── alert_rule.rb, alert.rb
├── services/
│   ├── rule_based_alert_service.rb
│   └── (lot_sensor_snapshot_service.rb 업데이트)
├── jobs/
│   └── sensor_reading_cleanup_job.rb
lib/
└── tasks/
    └── wdaq.rake
test/
├── tenancy/
│   └── tenant_isolation_test.rb
└── (도메인 테스트 신규)
.githooks/
└── pre-commit   # 용어 가이드
```

### 6.4 데이터 모델

```
Tenant(id, code:uniq, name, plan_tier, is_active)

(9개 도메인 테이블 + User + Session)
  + tenant_id:not_null:index
  + unique (tenant_id, code) 재설계

SensorReading(id, tenant_id, equipment_id, sensor_type, value:float,
              recorded_at:datetime, metadata:jsonb)
  index: (tenant_id, equipment_id, recorded_at)

AlertRule(id, tenant_id, name, sensor_type, operator, threshold_min, threshold_max,
          severity:enum, is_active)

Alert(id, tenant_id, alert_rule_id, equipment_id, sensor_reading_id,
      fired_at, acknowledged_at, acknowledged_by_user_id)
```

### 6.5 API

| 엔드포인트 | 용도 | 인증 |
|-----------|-----|-----|
| `POST /api/v1/sensor_readings` | WDAQ/시뮬레이터 수신 | **API 토큰 + tenant 식별 (토큰 스킴 = OI-06)** |
| `POST /api/v1/lot_snapshots` | LOT 스냅샷 | 세션 |
| `GET /quality/correlation?lot=...` | 상관 조회 (α) | 세션 |
| `GET /monitoring/alerts` | 알림 리스트 (γ) | 세션 |
| `PATCH /monitoring/alerts/:id/acknowledge` | 알림 확인 | 세션 |

### 6.6 Current.tenant 전파 규약 (C5 반영)

| 경로 | 설정 지점 | 방법 |
|-----|---------|------|
| HTTP 요청 | `ApplicationController#before_action` | 로그인 사용자의 `user.tenant` |
| Solid Queue 잡 | `ApplicationJob` — `around_perform` | `arguments`에 `tenant_id` serialize / `Current.tenant=` 복원 / 완료 후 `Current.reset` |
| ActionCable | `ApplicationCable::Connection#connect` | session에서 사용자 조회 후 `current_tenant` 설정. `Channel#subscribed`에서 `Current.tenant` 복원 |
| Rake 태스크 | Rake task 시작부 | `ENV.fetch("TENANT")`로 code 조회 → `Current.tenant=` 설정. 없으면 예외 |
| 시스템 레벨 | — | `Current.tenant=nil`에서 tenant-scoped 쿼리 실행 시 자동 예외 (lint) |

> 구현 가이드: 설계 문서 `docs/02-design/factory-box-pivot.design.md`에서 상세 코드 예시로 이어짐.

---

## 7. 일정 (3개월, 12주)

기준: 2026-04-20(월) ~ 2026-07-20(월)

| 주 | 기간 | 목표 | 산출물 |
|---|-----|-----|------|
| W1 | 04-20~04-26 | **Spike & 설계 + CI 구축 (M5)** | ActsAsTenant vs 수동 벤치, 마이그레이션 설계, 롤백 드릴 스크립트 초안, **CI 파이프라인 (SimpleCov + Rubocop + Brakeman) 가동**, `legacy-test-backfill.plan.md` 스텁 |
| W2 | 04-27~05-03 | A 레이어 1단계 + 주간 품질 | Tenant 모델, User.role, 기준정보 5테이블 tenant_id + 테스트, **주간 Brakeman 점검 시작** |
| W3 | 05-04~05-10 | A 레이어 2단계 + 주간 품질 | 생산/품질/센서 5테이블 tenant_id, online backfill 스크립트 |
| W4 | 05-11~05-17 | **롤백 드릴 + GnT 회귀 테스트 (G2 게이트)** | staging에서 Phase 0~2 전체 리허설 → 롤백 검증, GnT 기능 회귀 그린 |
| W5 | 05-18~05-24 | A' 관리자 권한 | FR-01a/b/c, tenant 전환 UI, 2테넌트 시드 |
| W6 | 05-25~05-31 | A 전파 규약 + 격리 침투 테스트 (G3 게이트) | ActiveJob/Cable/Rake 전파, 침투 테스트 10+ 케이스, **주간 침투 테스트 가동** |
| W7 | 06-01~06-07 | B 레이어 1단계 + 로드 테스트 #1 | SensorReading, API, 72h cleanup 잡, `wrk` 초기 부하 |
| W8 | 06-08~06-14 | B 레이어 2단계 + 로드 테스트 #2 (G4 게이트) | 시뮬레이터 완성, 부하 테스트, OI-05 파티셔닝 결정 |
| W9 | 06-15~06-21 | C 레이어 α+β | Correlation UI, Chartkick + 다운샘플링 |
| W10 | 06-22~06-28 | C 레이어 γ | AlertRule, RuleBasedAlertService, AlertChannel |
| W11 | 06-29~07-05 | **통합 회귀 + 누락 클린업** | 주간 누적 품질 항목 최종 점검, 누락 테스트 보강, CLAUDE.md/README 마무리 |
| W12 | 07-06~07-12 | **레드팀 3차 검토 + Acceptance Demo 4개 + G5 게이트** | 로드 테스트 #3, Demo 리허설, 레드팀 피드백 반영 |
| 예비 | 07-13~07-20 | 최종 승인 + PDCA report | G5 통과 확인, `/pdca report` |

---

## 8. 후속 로드맵

| Phase | 시기 | 주제 |
|-------|-----|-----|
| Phase 2 | 2026-08~10 | 실 WDAQ HW 연동 (MQTT/InfluxDB), **δ AI 백엔드 실구현** (정부과제 산출물), 레거시 테스트 backfill |
| Phase 3 | 2026-11~2027-01 | Track 2 (이카운트 연동), 2호 고객 유치 준비 |
| Phase 4 | 2027-02~ | Rails Engine 추출, 업종별 커스텀 모듈 |

---

## 9. Open Issues — 향후 결정 안건 (사용자 요청 방침)

> 현 시점에 확정되지 않은 주제는 **안건으로만 확보**하고 넘어간다. 각 안건은 Plan 진행 중 특정 게이트에서 해소한다.

| ID | 안건 | 해소 Owner | 해소 Gate (언제까지) | 미해소 시 기본값 |
|----|-----|----------|-------------------|---------------|
| ~~OI-01~~ | ~~`factory-box-strategy.md` 저장소 커밋~~ | ~~사용자~~ | ~~W1 종료 전~~ | **✅ 2026-04-19 해소** — `docs/factory-box-strategy.md` 커밋 완료 |
| **OI-02** | WDAQ 실 페이로드 스키마 합의 (정부과제 팀과) | 신호테크 R&D | W7 시작 전 | 시뮬레이터 임시 스키마 사용, W7 freeze 리스크 허용 |
| ~~OI-03~~ | ~~승인자 지정~~ | ~~사용자~~ | ~~W1 종료 전~~ | **✅ 2026-04-19 해소** — 사용자 본인(프로젝트 오너) 단독 승인 |
| ~~OI-04~~ | ~~인력/투입시간 확정~~ | ~~사용자~~ | ~~W1 종료 전~~ | **✅ 2026-04-19 해소** — 1인(사용자) + AI 페어링(Claude 상시), 주 40h 기준. 병행 업무 여부는 미기재(추후 필요 시 재평가) |
| **OI-05** | SensorReading PG 파티셔닝 도입 여부 | 개발자 | W8 부하 테스트 후 | NFR 미달 시 강제 도입 (R3) |
| **OI-06** | API 토큰 스킴 (JWT/HMAC/단순 key) | 개발자 | W6 종료 전 | 단순 API Key + DB 저장 (최소 구현) |
| **OI-07** | Staging 환경 존재/구축 | 사용자 | W3 종료 전 | Docker Compose로 로컬 staging 프로파일 구성 |
| **OI-08** | CI/CD (GitHub Actions 등) 구축 — SimpleCov + Rubocop + Brakeman | 개발자 | **W1 종료 전 (M5 반영, W2 → W1 전진)** | 미달 시 W2 신규 코드는 로컬 수동 검증. 기술부채 누적 위험 |
| **OI-09** | 데이터 보존/삭제 법적 근거 (72h 롤링) | 사용자 | W7 시작 전 | 기술적 필요에 의한 운영 정책으로만 문서화 |
| **OI-10** | config/application 네이밍 (`GntPop` → `FactoryBox`?) | 사용자 | Phase 2 진입 전 | Plan 기간 중 `GntPop::Application` 유지 |
| **OI-11** | 관찰성(로그 포맷/메트릭/대시보드) 기준 | 개발자 | W10 종료 전 | `lograge` + Rails 기본 로그, 대시보드 Phase 2 |
| **OI-12** | 보안 침투 테스트 수행자/시점 | 사용자 | W6 종료 전 | 내부 개발자가 침투 테스트 케이스 작성·수행 |

> 각 OI는 해소 시점에 본 Plan §9 테이블을 **그 자리에서 업데이트**하고 PR에 반영한다. 해소 이력은 Git 로그로 추적.

---

## 10. 롤백 플랜 (C4 반영) — GnT 운영 안전

### 10.1 원칙 (SLA 정의)

- **계획 중단 SLA**: 사전 공지된 저부하 시간대에 **≤ 10분** (maintenance mode 필요 시에만)
- **롤백 복구 SLA**: 장애 감지 후 **≤ 15분** 내 정상 응답 복귀
- **무중단 목표**: **Online migration 3단계(add nullable → backfill → not null)로 maintenance mode 생략**이 1순위 전략. 무중단이 불가능하다고 판단되는 단계만 계획 중단으로 전환.
- 모든 신규 마이그레이션은 **역방향(`db:rollback`) 가능**해야 함 (§4.2 DoD)
- 배포는 **사전 협의된 저부하 시간대**에만. 현장 교대 시간 회피.

> v0.5.1 변경: v0.5.0의 "운영 중단 0분"은 §10.2의 maintenance_on 절차와 자기모순이었다. 현실적 SLA로 재정의(M1).

### 10.2 배포 절차 (tenant_id 도입 마이그레이션 — Online 우선)

```
Phase 0 — 사전 (다운타임 없음)
  1. production DB 논리 백업 (pg_dump) — 롤백 Level 3 대비
  2. staging에서 전체 절차 리허설 → GnT 회귀 테스트 그린 (W4 완료 조건)
  3. 롤백 스크립트 staging 검증

Phase 1 — Online migration (다운타임 없음, 목표 상태)
  4. add_column tenant_id (nullable, default 1) — 기존 INSERT 호환 유지
  5. backfill tenant_id=1 (배치 단위, 각 배치 10초 이내, lock_timeout=1s)
  6. 코드 배포 — Current.tenant 훅 포함, 여전히 nullable 허용
  7. 모니터링 15분: 에러율 / 응답시간 / 로그인 성공률
  8. change_column null:false — ALTER 중 AccessExclusiveLock 발생 (PG 11+ 기준 짧음)
      * 이 단계만 lock 대기 가능 → 저부하 시간대(야간) 수행
      * lock_timeout=5s + statement_timeout=30s 설정

Phase 2 — 필요 시 계획 중단 (≤ 10분 SLA)
  9. Phase 1-8이 lock 경합으로 실패 시에만 maintenance_on → ALTER → maintenance_off
     (이 시나리오에서도 SLA 10분 내)

Phase 3 — 이상 발생 시 (≤ 15분 복구 SLA)
  10. §10.3 롤백 절차
```

> **목표**: Phase 1만으로 완결(무중단). Phase 2는 예비 경로.

### 10.3 롤백 절차

```
Level 1 (코드 롤백): git revert + 재배포, 스키마 유지
Level 2 (부분 롤백): maintenance_on → remove_column tenant_id → 구 배포
Level 3 (전체 복구): maintenance_on → pg_restore (§10.2 백업) → 구 배포
```

### 10.4 Pause 전환 조건 (R7 Kill-switch)

- W4 종료 시: A 레이어(멀티테넌시 + 롤백 드릴) 완료율 **< 70%**
- W6 종료 시: 격리 침투 테스트 실패율 **> 30%**
- W8 종료 시: 센서 API NFR **p95 > 1s** (파티셔닝 적용 후에도)

위 조건 1개라도 발화 시: **Plan Pause** → 사용자(OI-03 승인자)와 범위 재협상.

---

## 11. 승인

### 11.1 승인자 및 투입 인력
- **승인자(OI-03)**: 사용자 본인 (프로젝트 오너) — 2026-04-19 확정
- **투입 인력(OI-04)**: 1인(사용자) + Claude 상시 페어링, 주 40h 기준
- **작성자**: 신호테크놀로지 R&D (Claude 지원)

### 11.2 **승인 필수 게이트 (M2 반영, 셀프 승인 리스크 완화)**

승인자가 단독이더라도 아래 **게이트를 모두 통과하기 전에는 서명 불가**.

| 게이트 | 시점 | 통과 조건 | 판정 주체 |
|-------|-----|---------|---------|
| G1. Plan 승인 | Plan 최종화 | **레드팀 최종 검증 "승인" 판정** + 조건부 수정 완료 (✅ 2026-04-19 통과) | Claude 레드팀 서브에이전트 |
| G2. W4 Pass | W4 종료 | GnT 회귀 테스트 그린 + 롤백 드릴 성공 + §5 R1 Kill-switch 미발화 | 사용자 + Claude 공동 점검 |
| G3. W6 Pass | W6 종료 | 격리 침투 테스트 실패율 ≤ 30% + Current.tenant 전파 4경로 검증 완료 | Claude 레드팀 + 사용자 |
| G4. W8 Pass | W8 종료 | 센서 API NFR p95 < 1s 달성 (파티셔닝 결정 포함) | Claude 레드팀 + 사용자 |
| G5. 최종 승인 | W12 종료 | **레드팀 3차 "승인" 판정** + Acceptance Demo 4개 시나리오 통과 | Claude 레드팀 서브에이전트 |

> **원칙**: 레드팀 판정이 "반려"인 상태에서의 승인자 서명은 무효. 레드팀 1·2차가 v0.4.0 반려를 통해 **실제로 결함을 걸러낸 실적**이 있으므로(C1~C5), 3차 검토도 동일한 신뢰로 필수 게이트로 간주.

### 11.3 검토 이력

- 레드팀 1차 (v0.4.0, 2026-04-19) — **반려**: C1~C5 치명적 결함 지적
- 레드팀 2차 (v0.5.0, 2026-04-19) — **조건부 승인**: 5개 최소 수정 요구 (M1~M5)
- 레드팀 3차 (v0.5.1, 2026-04-19) — **승인**: 5개 수정 모두 🟢 완전 충족, 경미 이슈 4건(설계 단계로 이월)
- 레드팀 최종 (W12 예정) — Acceptance Demo 검증 (G5 게이트)

### 11.4 서명
- **서명일**: __________________ (G5 게이트 통과 후)
- **승인자 서명**: __________________

---

> **다음 단계**: v0.5.1 레드팀 2차 재검증 → `/pdca design factory-box-pivot` 설계 단계 진입
>
> W1 전 잔여 Open Issues: OI-02(WDAQ 실 페이로드), OI-05~OI-12 (각 Gate에서 해소)
