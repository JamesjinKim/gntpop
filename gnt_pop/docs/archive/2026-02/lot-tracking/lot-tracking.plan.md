# LOT 추적 (Lot Tracking) Planning Document

> **요약**: LOT 번호 기반 생산 이력 추적 및 조회 기능 구현
>
> **프로젝트**: GnT POP (생산시점관리 시스템)
> **버전**: 0.1.0
> **작성자**: GnT Dev Team
> **작성일**: 2026-02-12
> **상태**: Draft

---

## 1. 개요

### 1.1 목적

LOT 번호를 입력하면 해당 LOT의 전체 생산 이력(작업지시 → 공정 → 설비 → 작업자 → 수량 → 불량 내역)을 한눈에 확인할 수 있는 추적 기능을 구현합니다. 자동차 부품 제조업의 ISO 9001 / IATF 16949 품질추적성 요구사항에 대응하는 핵심 기능입니다.

### 1.2 배경

- 현재 생산실적 입력 시 LOT 번호가 자동 생성되고 있으나, LOT 기반 이력 추적 전용 화면이 없음
- 사이드바에 "LOT 추적" 메뉴 링크만 존재하고 실제 기능은 미구현 상태
- 고객 클레임/리콜 대응 시 LOT 기반 역추적(Reverse Traceability)이 필수
- 생산실적 목록의 Ransack 검색으로는 LOT 중심의 통합 이력 조회가 불가

### 1.3 관련 문서

- Plan: `docs/01-plan/features/production-tracking.plan.md`
- Design: `docs/02-design/features/production-tracking.design.md`
- 요구사항: `GNT_POP_PLAN.md` - 모듈 B: 생산관리

---

## 2. 범위

### 2.1 포함 범위 (In Scope)

- [x] LOT 번호 검색 전용 화면 (독립 라우트)
- [x] LOT 상세 이력 조회 (작업지시 → 공정 → 설비 → 작업자 → 수량)
- [x] LOT별 불량 내역 조회 (불량코드, 수량, 설명)
- [x] LOT 타임라인 표시 (작업 시작/종료 시간)
- [x] 사이드바 메뉴 연동 (기존 링크를 새 라우트로 변경)

### 2.2 제외 범위 (Out of Scope)

- 바코드/QR 스캔을 통한 LOT 조회 (Phase 3 후반)
- LOT 간 연결 관계(모-자 LOT) 추적 (Phase 4)
- LOT 이력 PDF 출력 (Phase 5)
- 역추적(제품 → LOT 역방향 조회) (Phase 4)

---

## 3. 요구사항

### 3.1 기능 요구사항

| ID | 요구사항 | 우선순위 | 상태 |
|----|----------|----------|------|
| FR-01 | LOT 번호 검색 전용 화면 제공 | High | Pending |
| FR-02 | LOT 번호 입력 시 해당 생산실적 상세 정보 표시 | High | Pending |
| FR-03 | LOT에 연결된 작업지시 정보(제품, 지시수량, 상태) 표시 | High | Pending |
| FR-04 | LOT의 공정/설비/작업자 정보 표시 | High | Pending |
| FR-05 | LOT의 양품/불량 수량 및 불량률 표시 | High | Pending |
| FR-06 | LOT에 연결된 불량기록 목록 표시 (불량코드별) | Medium | Pending |
| FR-07 | LOT 작업 타임라인 표시 (시작~종료 시간) | Medium | Pending |
| FR-08 | LOT 미발견 시 안내 메시지 표시 | Medium | Pending |
| FR-09 | 최근 검색 LOT 이력 표시 (세션 기반) | Low | Pending |

### 3.2 비기능 요구사항

| 카테고리 | 기준 | 측정 방법 |
|----------|------|-----------|
| 성능 | LOT 검색 응답시간 < 300ms | Rails 로그 측정 |
| 사용성 | LOT 번호 입력 후 Enter로 즉시 검색 | UI 검증 |
| 사용성 | 터치스크린 최적화 (최소 44px 터치 타겟) | UI 검증 |
| 보안 | 인증된 사용자만 접근 가능 | Authentication concern |

---

## 4. 성공 기준

### 4.1 완료 조건 (Definition of Done)

- [ ] LOT 추적 전용 화면에서 LOT 번호 검색 가능
- [ ] 검색 결과에 작업지시/공정/설비/작업자/수량/불량 정보 표시
- [ ] LOT 미발견 시 적절한 안내 메시지 표시
- [ ] 사이드바 "LOT 추적" 메뉴가 새 화면으로 연결
- [ ] 기존 기능에 영향 없음 (회귀 테스트)

### 4.2 품질 기준

- [ ] N+1 쿼리 없음 (eager loading 적용)
- [ ] Rubocop 린트 통과
- [ ] 반응형 레이아웃 (모바일/데스크톱)

---

## 5. 리스크 및 대응

| 리스크 | 영향 | 발생 가능성 | 대응 방안 |
|--------|------|------------|----------|
| LOT 데이터가 적어 검색 테스트 어려움 | Low | Medium | 시드 데이터에 다양한 LOT 추가 |
| 조회 쿼리 복잡도로 인한 성능 저하 | Medium | Low | includes로 eager loading, 인덱스 활용 |

---

## 6. 아키텍처 고려사항

### 6.1 프로젝트 레벨

| 레벨 | 특성 | 적합 대상 | 선택 |
|------|------|----------|:----:|
| **Starter** | 단순 구조 | 정적 사이트 | |
| **Dynamic** | 기능 기반 모듈, Service Objects | 웹앱, SaaS MVP | **V** |
| **Enterprise** | 엄격한 계층 분리 | 대규모 시스템 | |

### 6.2 주요 아키텍처 결정

| 결정 사항 | 옵션 | 선택 | 근거 |
|----------|------|------|------|
| 라우팅 방식 | A) 기존 production_results에 파라미터 추가 / B) 독립 컨트롤러 | B) 독립 컨트롤러 | SRP 준수, 관심사 분리 |
| 네임스페이스 | productions/lot_tracking | productions/lot_tracking | 기존 생산관리 네임스페이스 하위 |
| 뷰 구조 | 검색 + 결과를 단일 페이지에 표시 | 단일 페이지 | 사용자 흐름이 단순하여 별도 페이지 불필요 |

### 6.3 구현 구조

```
app/
├── controllers/
│   └── productions/
│       └── lot_tracking_controller.rb   # (신규) index, show
├── views/
│   └── productions/
│       └── lot_tracking/
│           ├── index.html.erb           # (신규) 검색 화면
│           └── show.html.erb            # (신규) LOT 상세 이력
├── config/
│   └── routes.rb                        # (수정) lot_tracking 라우트 추가
└── views/layouts/
    └── _sidebar.html.erb                # (수정) 메뉴 링크 변경
```

---

## 7. 구현 순서

### Step 1: 라우팅 및 컨트롤러 생성
1. `config/routes.rb`에 `productions/lot_tracking` 라우트 추가
2. `Productions::LotTrackingController` 생성 (index, show 액션)

### Step 2: LOT 검색 화면 (index)
1. LOT 번호 검색 폼 (텍스트 입력 + 검색 버튼)
2. 검색 결과 없을 시 안내 메시지

### Step 3: LOT 상세 이력 화면 (show)
1. LOT 기본 정보 카드 (LOT 번호, 작업일시, 양품/불량 수량)
2. 작업지시 정보 섹션 (제품, 지시코드, 수량, 상태)
3. 공정/설비/작업자 정보 섹션
4. 불량 기록 테이블 (불량코드, 수량, 설명)
5. 작업 타임라인 (시작~종료)

### Step 4: 사이드바 연동
1. `_sidebar.html.erb`의 LOT 추적 링크를 새 라우트로 변경

---

## 8. 다음 단계

1. [ ] Design 문서 작성 (`lot-tracking.design.md`)
2. [ ] 구현 시작
3. [ ] Gap 분석 및 검증

---

## 버전 이력

| 버전 | 날짜 | 변경 사항 | 작성자 |
|------|------|----------|--------|
| 0.1 | 2026-02-12 | 초안 작성 | GnT Dev Team |
