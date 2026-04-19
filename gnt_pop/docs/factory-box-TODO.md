# Factory Box Pivot — 실행 TODO

> **접근**: 애자일, 작은 단위, 실행 우선. 필요한 설계는 **코드와 함께** 작성.
> **전략**: `factory-box-strategy.md` (ground truth)
> **역사 자료**: `docs/archive/2026-04-factory-box-planning/` (Plan v0.5.1, 참고만)
> **마지막 갱신**: 2026-04-19

## 대원칙
- GnT 운영을 망가뜨리지 않는다 (롤백 가능한 마이그레이션만)
- 한 번에 하나씩 작은 PR로
- 테스트가 있을 때만 "완료"
- 설계 문서는 필요해지면 그때 쓴다

## Sprint 0 — 환경 정리 (필요 시)
- [ ] `.github/workflows/ci.yml` 실측 후 SimpleCov·Bullet 필요하면 **그때** 추가
- [ ] `config/database.yml`이 PG인지 SQLite인지 한 번 확인 + CLAUDE.md 정정
- [ ] `factory-box-pivot` 브랜치 생성, `gnt-v1-final` 태그 부착

## Sprint 1 — 멀티테넌시 최소 구현
- [ ] `Tenant` 모델 + 마이그레이션 (code, name)
- [ ] GnT 기본 테넌트 시드 (id=1)
- [ ] 작게 시작: `Product` 1개에만 `tenant_id` 추가 + `default_scope` + 테스트
- [ ] 작동하면 나머지 도메인 테이블로 확산 (한 번에 전부 X, 2~3개씩)
- [ ] `User`에 tenant_id, 로그인 시 `Current.tenant` 세팅
- [ ] acts_as_tenant gem 도입 여부는 **수동으로 2~3개 해본 뒤 결정**

## Sprint 2 — WDAQ 시뮬레이터 (가장 단순한 버전)
- [ ] `SensorReading` 테이블 (tenant_id, equipment_id, sensor_type, value, recorded_at)
- [ ] `POST /api/v1/sensor_readings` 최소 구현 (토큰 인증은 하드코딩으로 시작)
- [ ] `rake wdaq:simulate` — 5초마다 랜덤 데이터 5종 생성
- [ ] 브라우저에서 데이터 들어오는지 확인 (대시보드 카드 1개로도 충분)

## Sprint 3 — POP × WDAQ 상관 (Level α만)
- [ ] LOT 선택 → 해당 기간의 SensorReading 리스트 표시 (테이블)
- [ ] 차트는 **필요성 확인 후**에 추가
- [ ] 룰 엔진·알림·WebSocket은 **기본 조회가 쓸만할 때**만 진행

## Sprint 4 — 알림 (필요하면)
- [ ] 하드코딩 임계치부터 시작 (진동 > 2.0)
- [ ] 동작 확인 후 `AlertRule` 모델로 추출
- [ ] WebSocket은 **폴링으로 먼저 해보고** 필요하면 ActionCable

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

## 다음에 할 단 하나의 일
**Sprint 0 체크리스트 첫 항목부터**. 다음 세션에서 이것만 확인하면 됨.
