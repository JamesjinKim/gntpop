# Factory Box Pivot — 실행 TODO

> **접근**: 애자일, 작은 단위, 실행 우선. 필요한 설계는 **코드와 함께** 작성.
> **전략**: `factory-box-strategy.md` (ground truth)
> **역사 자료**: `docs/archive/2026-04-factory-box-planning/` (Plan v0.5.1, 참고만)
> **마지막 갱신**: 2026-04-19 (실측 기반 진행 상태 반영)
>
> **범례**: `[x]` 완료 · `[~]` 부분/진행중 · `[ ]` 미완 · `[!]` 결정/합의 필요

## 대원칙
- GnT 운영을 망가뜨리지 않는다 (롤백 가능한 마이그레이션만)
- 한 번에 하나씩 작은 PR로
- 테스트가 있을 때만 "완료"
- 설계 문서는 필요해지면 그때 쓴다

## Sprint 0 — 환경 정리 ✅ 완료 (2026-04-19)
- [x] `.github/workflows/ci.yml` 실측 — ci.yml 존재(scan_ruby/scan_js/lint/test/system-test). SimpleCov/Bullet은 미도입(의도대로 "필요할 때")
- [x] `config/database.yml` = PostgreSQL 확인 + CLAUDE.md "SQLite3→PostgreSQL" 정정
- [x] `gnt-v1-final` 태그 부착 → 커밋 `6f3b854` (GnT v1 마지막 버그수정)
- [x] ~~`factory-box-main` 브랜치 생성~~ → **옵션 A 채택**: 단일 브랜치(`main`)에서 계속 진행. 1인 프로젝트 YAGNI. GnT v1 복귀는 `gnt-v1-final` 태그로 가능

## Sprint 1 — 멀티테넌시(다중임대) 최소 구현 (진행률 0%)
- [ ] `Tenant` 모델 + 마이그레이션 (code, name) — `app/models/tenant.rb` 없음
- [ ] GnT 기본 테넌트 시드 (id=1) — 없음
- [ ] 작게 시작: `Product` 1개에만 `tenant_id` 추가 + `default_scope` + 테스트 — schema에 tenant 컬럼 0건
- [ ] 작동하면 나머지 도메인 테이블로 확산 (한 번에 전부 X, 2~3개씩)
- [ ] `User`에 tenant_id, 로그인 시 `Current.tenant` 세팅 — `Current` 클래스는 있으나 `tenant` 속성 없음
- [!] acts_as_tenant gem 도입 여부는 **수동으로 2~3개 해본 뒤 결정** — 현재 Gemfile 미도입

## Sprint 2 — WDAQ 시뮬레이터 (진행률 ~20%, ⚠️ 스키마 방향 재합의 필요)

**⚠️ 현 코드와 TODO의 스키마 방향 불일치**:
- TODO 설계: `SensorReading` 정규화 행 (tenant_id, equipment_id, sensor_type, value, recorded_at)
- 현재 스캐폴딩: `LotSensorSnapshot` — jsonb 통째 저장 (sensor_data/safety_data/statistics)
- 둘 중 하나로 합의해야 Sprint 2 계속 가능

- [!] **스키마 방향 합의** (SensorReading 정규화 vs LotSensorSnapshot jsonb)
- [ ] `SensorReading` 테이블 (tenant_id, equipment_id, sensor_type, value, recorded_at) — 미생성
- [~] `POST /api/v1/sensor_readings` 최소 구현 (토큰 인증은 하드코딩으로 시작) — 라우트·컨트롤러 **스캐폴딩만** 존재. 실제 저장 로직 없음(`render json: { status: "ok", message: "...ready" }` placeholder)
- [ ] `rake wdaq:simulate` — 5초마다 랜덤 데이터 5종 생성 — `lib/tasks/` 비어있음
- [ ] 브라우저에서 데이터 들어오는지 확인 (대시보드 카드 1개로도 충분) — `app/views/dashboard/`에 sensor 관련 코드 0건

## Sprint 3 — POP × WDAQ 상관 (Level α만, 진행률 ~10%)
- [~] LOT 선택 → 해당 기간의 SensorReading 리스트 표시 (테이블) — `/api/v1/lot_snapshots` JSON index는 존재, **POP UI 연동 없음**
- [ ] 차트는 **필요성 확인 후**에 추가 — 미검토
- [!] 룰 엔진·알림·WebSocket은 **기본 조회가 쓸만할 때**만 진행 — ⚠️ **원칙 위반**: `SensorChannel`/`AlertChannel`(ActionCable)·`EquipmentStatusInferenceService`(vibration>2.0, temp>80 하드코딩) 이미 선제 스캐폴딩. 유지/제거/보류 결정 필요

## Sprint 4 — 알림 (진행률 ~10%, 원칙 위반 의심)
- [~] 하드코딩 임계치부터 시작 (진동 > 2.0) — `EquipmentStatusInferenceService`에 이미 존재(추론 용도, 알림 아님)
- [ ] 동작 확인 후 `AlertRule` 모델로 추출 — 없음
- [!] WebSocket은 **폴링으로 먼저 해보고** 필요하면 ActionCable — ⚠️ **원칙 위반**: AlertChannel 이미 스캐폴딩(`stream_from "alerts_all"/"alerts_safety"/"alerts_quality"`). 폴링 먼저 원칙과 모순

## 멈춤 신호 (언제든 재평가)
- 한 스프린트가 1주 넘게 걸리면 → 범위를 쪼갰는지 재점검
- 레드팀 검토 충동이 생기면 → 메모리 `feedback_avoid_over_engineering.md` 읽기
- "혹시 나중에 필요할지도" 추가 욕구 → YAGNI 위반, 제거

## 확정된 결정 (바꿀 일 없음)
- Rails 8.1 + PostgreSQL + Hotwire (현 스택 유지)
- 멀티테넌시 Level 1 (tenant_id 컬럼)
- GnT = 내부 테넌트 #1 (유료 고객 아님)
- GnT 도메인 용어 유지 (컨버터/트랜스포머)
- AI(Autoencoder)는 정부과제 산출물 나오면 그때 붙임, 지금은 손대지 않음
- **저장소 전략: In-place 단일 브랜치** (2026-04-19 확정) — `main`에서 계속 작업, `gnt-v1-final` 태그(6f3b854)로 GnT v1 복귀 가능. 별도 `factory-box-main` 브랜치 생략(YAGNI)

## 현재 이슈 요약 (2026-04-19 실측)
1. **스키마 불일치** (Sprint 2): `SensorReading` 정규화 vs `LotSensorSnapshot` jsonb. 방향 합의 필요
2. **선제 스캐폴딩** (Sprint 3/4): channels/inference service가 애자일 원칙 위반으로 존재. 유지/제거 결정 필요
3. **`sensor_readings_controller`는 placeholder** — 스키마 결정 뒤 실제 저장 로직 작성

## 다음에 할 단 하나의 일
Sprint 0 완료. **Sprint 1 첫 항목 착수**: `Tenant` 모델 + 마이그레이션(code, name) 만들기 — 작은 스프린트 최소 구현.

**Sprint 2 진입 전에 스키마 방향 합의(`SensorReading` vs `LotSensorSnapshot`)를 먼저 결정**.
