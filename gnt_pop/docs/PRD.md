# PRD — Factory Box (Mini MES + WDAQ 4.0)

- **Version**: 0.1 (draft)
- **Date**: 2026-04-19
- **Status**: Track 1 MVP Planning
- **Stack**: Rails 8.1 + PostgreSQL + Hotwire (변경 없음)

> 본 문서는 Product 관점 겉표지입니다. 상세 전략은 [strategy.md](factory-box-strategy.md), 실행 체크리스트는 [TODO.md](factory-box-TODO.md)를 참고하세요.

## 1. What — Product Summary

한국 중소제조업을 위한 **Mini MES + WDAQ 4.0 올인원 SaaS**.
한 제품 안에 생산관리와 센서 기반 품질관리가 통합되어, 별도 시스템 연동 없이 도입 가능.

## 2. Why — Problem & Motivation

- 한국 중소제조업: 기존 MES는 고가·복잡도 높음, 품질 문제 사후 대응 중심
- 신호테크 WDAQ 기술(삼성디스플레이 납품 검증)의 중소기업 SaaS 확장 여지
- Track 1: 131K SME 시장, 올인원으로 진입 장벽 최소화

## 3. Who — Target Users

- **1차 타깃**: 50~200명 규모 한국 중소 제조업체
- **Anchor 테넌트**: GnT (컨버터/트랜스포머 제조, 내부 레퍼런스 #1, 유료 고객 아님)

## 4. Core Features (MVP, 3개월)

### 4.1 Mini MES 기본 (현 gnt_pop 자산 재사용)
- **Masters**: Product / Process / Equipment / Worker / DefectCode
- **Productions**: WorkOrder / ProductionResult / LOT Tracking
- **Quality**: Inspection / Defect Analysis / SPC
- **Monitoring**: Production Board / Equipment Status

### 4.2 WDAQ 4.0 통합
- HTTP 수신 API: `POST /api/v1/sensor_readings`, `POST /api/v1/lot_snapshots`
- WDAQ 시뮬레이터 (rake task, 5초 주기 랜덤 데이터)
- Equipment Status 자동 추론 (룰 기반)
- LOT × Sensor 상관 **Level α** (리스트 조회만, 차트는 후순위)

### 4.3 멀티테넌시 (Level 1)
- `tenant_id` 컬럼 스코핑 + `Current.tenant`
- GnT 테넌트 #1 시드 (id=1)

## 5. Non-functional Requirements

- 모든 마이그레이션 롤백 가능 (`rails db:rollback` 안전)
- 테스트가 있을 때만 "완료" (PR에 테스트 포함)
- 한 번에 하나씩 작은 PR (< 300 LOC 권장)
- 공장 현장 터치 44px 최소 유지
- GnT 운영 중단 없이 피벗 진행

## 6. Out of Scope (의도적 제외)

| 항목 | 사유 |
|---|---|
| AI (Autoencoder / Level δ) | 정부과제 산출물 이후 |
| UDP 직접 수신 | WDAQ 하드웨어 확정 후 Bridge 데몬으로 |
| 모바일 네이티브 앱 | Web-only, Hotwire로 충분 |
| 유료 billing / SLA / 고급 ACL | 2호 테넌트 생길 때 |
| GUI 대규모 개선 | YAGNI, 구체 고통점 나올 때 |
| "예지보전"·"고장 예측" 용어 | → "품질 사고 예방"·"이상 조기 감지" 사용 |

## 7. Quantitative Goals (3개월)

- [ ] 멀티테넌시 Level 1 동작 (GnT 테넌트 실 운영 1건)
- [ ] WDAQ HTTP 수신 API + 시뮬레이터 연동 확인
- [ ] Dashboard에 Mini MES 지표 + 센서 상태 통합 조회
- [ ] 마이그레이션 롤백 100% 성공
- [ ] 테스트 커버리지 기존 수준 이상 유지

## 8. Execution Approach

- **저장소 전략 (In-place 단일 브랜치)**: 현 `gnt_pop` 저장소 유지. `gnt-v1-final` 태그(커밋 6f3b854)로 GnT v1 동결, 이후 피벗 작업은 `main`에서 계속 (1인 프로젝트 YAGNI, 별도 브랜치 생략)
- **애자일 Sprint**: 0(환경 정리) → 1(멀티테넌시) → 2(WDAQ 시뮬) → 3(POP×WDAQ Level α) → 4(알림, 필요 시)
- **설계 원칙**: 필요해지면 코드와 함께 작성, 선제 ADR 금지 (메모리 `feedback_avoid_over_engineering.md`)

## 9. Related Documents

- 전략 (ground truth): [factory-box-strategy.md](factory-box-strategy.md) v5
- 실행 체크리스트: [factory-box-TODO.md](factory-box-TODO.md)
- 역사 자료: [docs/archive/2026-04-factory-box-planning/](archive/2026-04-factory-box-planning/)

## 10. Open Questions (미확정 안건)

- [ ] factory_box 최종 브랜드명 (GnT 무관 네이밍 검토)
- [ ] 2호 테넌트 도입 시점 (영업 타임라인)
- [ ] 정부과제 WDAQ 실 하드웨어 인도 일정 → UDP Bridge 도입 시점 결정 입력
