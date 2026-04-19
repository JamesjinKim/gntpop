# 생산실적 관리 (Production Tracking) Planning Document

> **요약**: LOT 기반 생산실적 등록/조회/통계 기능 구현
>
> **프로젝트**: GnT POP (생산시점관리 시스템)
> **버전**: 0.2.0
> **작성자**: GnT Dev Team
> **작성일**: 2026-02-11
> **상태**: Draft

---

## 1. 개요

### 1.1 목적

생산 현장에서 작업자가 공정별 생산실적(양품/불량 수량)을 실시간으로 입력하고, LOT 단위로 이력을 추적하며, 관리자가 생산 현황을 통계적으로 분석할 수 있는 기능을 구현합니다.

### 1.2 배경

- GnT는 전기 상용차용 컨버터, 트랜스포머 인덕터 등을 제조하는 기업
- 현재 Phase 1(기반 구축)이 완료되어 인증/대시보드 스켈레톤이 구현됨
- Phase 2(기준정보)와 Phase 3(생산관리)를 함께 진행하여 핵심 생산실적 기능을 구현
- 자동차 부품 제조업 특성상 LOT 추적이 필수 (ISO 9001 대응)

### 1.3 관련 문서

- 요구사항: `GNT_POP_PLAN.md` - 모듈 B: 생산관리
- 체크리스트: `GNT_POP_MVP_CHECKLIST.md` - Phase 2, 3
- 비전: `GNT_POP_VISION.md`

---

## 2. 범위

### 2.1 포함 범위 (In Scope)

- [x] 기준정보 모델 생성 (Product, ManufacturingProcess, Equipment, Worker, DefectCode)
- [x] 작업지시(WorkOrder) CRUD
- [x] 생산실적(ProductionResult) 입력/조회
- [x] LOT 번호 자동생성 서비스
- [x] 불량기록(DefectRecord) 입력
- [x] 공정별 생산현황 조회 (일별/주별/월별)
- [x] 대시보드 실제 데이터 연동 (목업 데이터 대체)
- [x] 시드 데이터 작성 (초기 기준정보)

### 2.2 제외 범위 (Out of Scope)

- 바코드 스캔 연동 (Phase 3 후반)
- 실시간 ActionCable/Turbo Streams 갱신 (Phase 5)
- SPC 통계 분석 (Phase 4)
- 품질검사 입력 (Phase 4)
- PDF 보고서 생성 (Phase 5)
- 모바일/터치스크린 최적화 UI (Phase 3 후반)

---

## 3. 요구사항

### 3.1 기능 요구사항

| ID | 요구사항 | 우선순위 | 상태 |
|----|----------|----------|------|
| FR-01 | 기준정보(제품/공정/설비/작업자/불량코드) CRUD | High | Pending |
| FR-02 | 작업지시서 등록 (제품, 수량, 계획일, 우선순위) | High | Pending |
| FR-03 | 작업지시 코드 자동생성 (WO-YYYYMMDD-NNN) | High | Pending |
| FR-04 | 작업지시 상태 관리 (계획/진행중/완료/취소) | High | Pending |
| FR-05 | 생산실적 입력 (작업지시 → 공정 → 양품/불량 수량) | High | Pending |
| FR-06 | LOT 번호 자동생성 (L-YYYYMMDD-제품코드-NNN) | High | Pending |
| FR-07 | 공정별 생산현황 조회 (기간별 필터) | Medium | Pending |
| FR-08 | 불량유형별 기록 및 집계 | Medium | Pending |
| FR-09 | 대시보드 실제 데이터 연동 | Medium | Pending |
| FR-10 | 기준정보 검색 및 페이지네이션 | Medium | Pending |

### 3.2 비기능 요구사항

| 카테고리 | 기준 | 측정 방법 |
|----------|------|-----------|
| 성능 | 생산실적 입력 응답시간 < 500ms | Rails 로그 측정 |
| 성능 | 목록 조회 1000건 이상에서 < 2초 | 페이지네이션 + 인덱스 적용 |
| 보안 | 인증된 사용자만 접근 가능 | Authentication concern 적용 |
| 데이터 무결성 | LOT 번호 유니크 보장 | DB unique index |
| 사용성 | 터치스크린에서 최소 44px 터치 타겟 | UI 검증 |

---

## 4. 성공 기준

### 4.1 완료 조건 (Definition of Done)

- [ ] 모든 기능 요구사항(FR-01~FR-10) 구현 완료
- [ ] 기준정보 시드 데이터로 초기 데이터 입력 가능
- [ ] 작업지시 → 생산실적 입력 → 조회 전체 흐름 동작
- [ ] 대시보드에 실제 DB 데이터 표시
- [ ] 단위 테스트 작성 및 통과
- [ ] Rubocop 린트 통과

### 4.2 품질 기준

- [ ] 테스트 커버리지 80% 이상 (모델, 서비스 기준)
- [ ] Rubocop 에러 0건
- [ ] Brakeman 보안 경고 0건
- [ ] N+1 쿼리 없음

---

## 5. 리스크 및 대응

| 리스크 | 영향 | 발생 가능성 | 대응 방안 |
|--------|------|------------|----------|
| 기준정보 모델 간 복잡한 관계로 인한 성능 저하 | Medium | Medium | eager loading, 인덱스 최적화 |
| LOT 번호 중복 발생 가능성 | High | Low | DB unique constraint + 서비스 레벨 검증 |
| 대시보드 쿼리 복잡도 증가 | Medium | Medium | 캐싱(Solid Cache) 활용, 집계 쿼리 최적화 |
| 기존 목업 대시보드와의 호환성 | Low | Medium | 점진적 대체 (영역별 실데이터 전환) |

---

## 6. 아키텍처 고려사항

### 6.1 프로젝트 레벨

| 레벨 | 특성 | 적합 대상 | 선택 |
|------|------|----------|:----:|
| **Starter** | 단순 구조 | 정적 사이트, 포트폴리오 | |
| **Dynamic** | 기능 기반 모듈, BaaS 연동 | 웹앱, SaaS MVP | **V** |
| **Enterprise** | 엄격한 계층 분리, DI, 마이크로서비스 | 대규모 시스템 | |

### 6.2 주요 아키텍처 결정

| 결정 사항 | 옵션 | 선택 | 근거 |
|----------|------|------|------|
| 프레임워크 | Rails 8 | Rails 8 | 이미 Phase 1에서 구축 완료 |
| 프론트엔드 | Hotwire (Turbo + Stimulus) | Hotwire | Rails 8 기본, SPA 수준 UX |
| CSS | Tailwind CSS v4 | Tailwind v4 | 이미 설정 완료, 터치 최적화 용이 |
| 데이터베이스 | SQLite3 | SQLite3 | MVP 단계 적합, 추후 PostgreSQL 전환 가능 |
| 검색/필터링 | Ransack | Ransack | Gem 이미 설치됨 |
| 페이지네이션 | Pagy | Pagy | 경량, 성능 우수 |
| 테스트 | Minitest | Minitest | Rails 기본 테스트 프레임워크 |
| 비즈니스 로직 | Service Objects | Service Objects | 컨트롤러 경량화, 단위 테스트 용이 |

### 6.3 Rails 프로젝트 구조

```
선택 레벨: Dynamic (Rails MVC + Service Objects)

폴더 구조:
┌─────────────────────────────────────────────────┐
│ app/                                            │
│   controllers/                                  │
│     productions/                                │
│       work_orders_controller.rb                 │
│       production_results_controller.rb          │
│     masters/                                    │
│       products_controller.rb                    │
│       manufacturing_processes_controller.rb     │
│       equipments_controller.rb                  │
│       workers_controller.rb                     │
│       defect_codes_controller.rb                │
│   models/                                       │
│     product.rb                                  │
│     manufacturing_process.rb                    │
│     equipment.rb                                │
│     worker.rb                                   │
│     defect_code.rb                              │
│     work_order.rb                               │
│     production_result.rb                        │
│     defect_record.rb                            │
│   services/                                     │
│     lot_generator_service.rb                    │
│     work_order_code_generator_service.rb        │
│   views/                                        │
│     productions/                                │
│     masters/                                    │
└─────────────────────────────────────────────────┘
```

---

## 7. 컨벤션 사전 확인

### 7.1 기존 프로젝트 컨벤션

- [x] `CLAUDE.md`에 코딩 컨벤션 섹션 있음
- [ ] `docs/01-plan/conventions.md` 존재
- [ ] Rubocop 설정 (`.rubocop.yml`)
- [x] Tailwind CSS 테마 설정 완료 (`application.css`)

### 7.2 정의/확인 필요 컨벤션

| 카테고리 | 현재 상태 | 정의 필요 사항 | 우선순위 |
|----------|-----------|--------------|:--------:|
| **네이밍** | 존재 | Rails 표준 (snake_case, PascalCase) | High |
| **폴더 구조** | 부분적 | 네임스페이스별 컨트롤러 분리 | High |
| **라우팅** | 기본만 | RESTful 리소스 라우팅 체계 | High |
| **에러 처리** | 미정의 | 표준 에러 처리 패턴 | Medium |
| **시드 데이터** | 미정의 | 개발/테스트 데이터 분리 | Medium |

### 7.3 환경 변수

| 변수 | 용도 | 범위 | 생성 필요 |
|------|------|------|:---------:|
| `RAILS_MASTER_KEY` | 시크릿 암호화 | Server | 이미 존재 |
| `DATABASE_URL` | DB 연결 (추후) | Server | 추후 |

---

## 8. 구현 순서

### Step 1: 기준정보 모델 및 마이그레이션 (Phase 2)
1. Product, ManufacturingProcess, Equipment, Worker, DefectCode 모델 생성
2. DB 마이그레이션 실행
3. 모델 간 관계(associations) 설정
4. 유효성 검증(validations) 추가
5. 시드 데이터 작성

### Step 2: 기준정보 CRUD (Phase 2)
1. Masters 네임스페이스 컨트롤러 생성
2. 각 기준정보별 index/new/edit/show 뷰 작성
3. Ransack 검색 + Pagy 페이지네이션 적용
4. 사이드바 메뉴 연동

### Step 3: 작업지시 관리 (Phase 3)
1. WorkOrder 모델 및 마이그레이션
2. 작업지시 코드 자동생성 서비스
3. 작업지시 CRUD 컨트롤러/뷰
4. 상태 관리 (plan → in_progress → completed/cancelled)

### Step 4: 생산실적 입력 (Phase 3)
1. ProductionResult 모델 및 마이그레이션
2. LOT 번호 자동생성 서비스 (LotGeneratorService)
3. 생산실적 입력 폼 (작업지시 → 공정 → 설비/작업자 → 수량)
4. DefectRecord 모델 및 불량 기록 연동

### Step 5: 생산현황 조회 및 대시보드 연동
1. 공정별 생산현황 조회 화면
2. 기간별(일/주/월) 필터
3. 대시보드 목업 데이터 → 실제 DB 데이터 전환
4. 생산 KPI 쿼리 최적화

---

## 9. 다음 단계

1. [ ] Design 문서 작성 (`production-tracking.design.md`)
2. [ ] 팀 리뷰 및 승인
3. [ ] 구현 시작 (Step 1부터 순차 진행)

---

## 버전 이력

| 버전 | 날짜 | 변경 사항 | 작성자 |
|------|------|----------|--------|
| 0.1 | 2026-02-11 | 초안 작성 | GnT Dev Team |
