# 품질관리 (Quality Management) Planning Document

> **요약**: 검사결과 입력/조회, 불량분석 통계, SPC 관리도 3개 기능 구현
>
> **프로젝트**: GnT POP (생산시점관리 시스템)
> **버전**: 0.1.0
> **작성자**: GnT Dev Team
> **작성일**: 2026-02-12
> **상태**: Draft

---

## 1. 개요

### 1.1 목적

GnT POP 시스템의 품질관리 모듈(모듈 C)을 구현합니다. 사이드바의 품질관리 섹션 하위 3개 메뉴(검사결과, 불량분석, SPC)를 실제 기능으로 연결하여, 수입/공정/출하 검사 결과를 입력하고 불량 데이터를 분석하며 SPC 관리도를 제공합니다.

### 1.2 배경

- GNT_POP_PLAN.md의 Phase 4 (품질관리)에 해당하는 기능
- 사이드바에 검사결과, 불량분석, SPC 메뉴가 `#` 링크로 존재하나 미구현
- ISO 9001 인증 기업으로 품질검사 이력관리 필수
- 자동차 부품 제조업 특성상 IATF 16949 품질추적성 요구

### 1.3 관련 문서

- 요구사항: `GNT_POP_PLAN.md` - 모듈 C: 품질관리, Phase 4
- 기존 구현: production-tracking (생산실적, 불량기록 입력)
- DB 참조: `GNT_POP_PLAN.md` - 007_create_inspection_results.rb 마이그레이션 스키마

---

## 2. 범위

### 2.1 포함 범위 (In Scope)

#### 2.1.1 검사결과 (Inspection Results)
- [x] inspection_results 테이블 생성 (마이그레이션)
- [x] 검사 유형별 입력: 수입검사, 공정검사, 출하검사
- [x] 검사 결과 목록 조회 (필터: LOT 번호, 검사유형, 판정결과)
- [x] 검사 결과 상세 조회
- [x] 검사 항목별 측정값 입력 (전압, 전류, 절연저항 등)
- [x] 합격/불합격 판정 표시

#### 2.1.2 불량분석 (Defect Analysis)
- [x] 기간별 불량 통계 조회 (일간/주간/월간)
- [x] 불량유형별 파레토 차트 (Chartkick)
- [x] 공정별 불량률 비교 차트
- [x] 제품별 불량률 비교 차트
- [x] 불량 추이 차트 (일별 불량률 변화)

#### 2.1.3 SPC (Statistical Process Control)
- [x] 검사 데이터 기반 X-bar R 관리도 표시
- [x] 관리 한계선 (UCL, CL, LCL) 자동 계산
- [x] 공정능력지수 (Cp, Cpk) 계산 및 표시
- [x] 검사항목/기간 선택 필터

### 2.2 제외 범위 (Out of Scope)

- 바코드/QR 스캔을 통한 검사 결과 입력 (Phase 5 이후)
- CAPA (시정/예방 조치) 관리 (MES 확장 시)
- 8D Report 생성 (MES 확장 시)
- 외부 검사장비 연동 (자동 측정값 수집)
- 검사성적서 PDF 출력 (Phase 5)

---

## 3. 요구사항

### 3.1 기능 요구사항

#### 검사결과

| ID | 요구사항 | 우선순위 | 상태 |
|----|----------|----------|------|
| FR-01 | inspection_results 테이블 및 InspectionResult 모델 생성 | High | Pending |
| FR-02 | 검사유형 분류 (수입검사/공정검사/출하검사) | High | Pending |
| FR-03 | 검사 결과 CRUD (입력/조회/수정/삭제) | High | Pending |
| FR-04 | 검사 결과 목록에서 LOT 번호, 검사유형, 판정으로 필터 | High | Pending |
| FR-05 | 검사 항목별 측정값 입력 (항목명, 규격, 측정값, 판정) | Medium | Pending |
| FR-06 | LOT 기반 검사이력 연동 (LOT 추적에서 검사결과 확인) | Medium | Pending |

#### 불량분석

| ID | 요구사항 | 우선순위 | 상태 |
|----|----------|----------|------|
| FR-07 | 기간별 불량 통계 대시보드 | High | Pending |
| FR-08 | 불량유형별 파레토 차트 | High | Pending |
| FR-09 | 공정별 불량률 비교 차트 | Medium | Pending |
| FR-10 | 제품별 불량률 비교 차트 | Medium | Pending |
| FR-11 | 일별 불량률 추이 차트 | Medium | Pending |

#### SPC

| ID | 요구사항 | 우선순위 | 상태 |
|----|----------|----------|------|
| FR-12 | X-bar R 관리도 차트 | High | Pending |
| FR-13 | UCL/CL/LCL 자동 계산 | High | Pending |
| FR-14 | 공정능력지수 (Cp, Cpk) 표시 | High | Pending |
| FR-15 | 검사항목/기간 필터 | Medium | Pending |

### 3.2 비기능 요구사항

| 카테고리 | 기준 | 측정 방법 |
|----------|------|-----------|
| 성능 | 불량분석 차트 로딩 < 500ms | Rails 로그 측정 |
| 성능 | SPC 계산 (1000건 데이터) < 1초 | Service Object 벤치마크 |
| 사용성 | 터치스크린 최적화 (최소 44px 터치 타겟) | UI 검증 |
| 보안 | 인증된 사용자만 접근 가능 | Authentication concern |

---

## 4. 성공 기준

### 4.1 완료 조건 (Definition of Done)

- [ ] inspection_results 테이블 생성 및 시드 데이터 투입
- [ ] 검사결과 CRUD 화면 동작
- [ ] 불량분석 차트 3종 이상 표시
- [ ] SPC X-bar R 관리도 표시 및 Cp/Cpk 계산
- [ ] 사이드바 3개 메뉴 실제 화면으로 연결
- [ ] 기존 기능 회귀 없음

### 4.2 품질 기준

- [ ] N+1 쿼리 없음 (eager loading 적용)
- [ ] Service Object로 SPC 계산 로직 분리
- [ ] 반응형 레이아웃 (모바일/데스크톱)

---

## 5. 리스크 및 대응

| 리스크 | 영향 | 발생 가능성 | 대응 방안 |
|--------|------|------------|----------|
| 검사 데이터 부족으로 SPC 의미 없음 | Medium | High | 시드 데이터에 충분한 검사 결과 생성 |
| Chartkick/Chart.js 호환성 | Low | Low | 이미 Gemfile에 포함 여부 확인, 필요 시 추가 |
| SPC 계산 로직 복잡도 | Medium | Medium | SpcCalculatorService로 분리하여 단위 테스트 |

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
| 네임스페이스 | A) quality/ 네임스페이스 | quality/ | GNT_POP_PLAN.md 구조 준수 |
| 검사 데이터 구조 | A) JSONB로 항목 저장 / B) inspection_items 별도 테이블 | B) 별도 테이블 | SQLite3에서 JSONB 제한적, 정규화 우선 |
| 차트 라이브러리 | A) Chartkick / B) Chart.js 직접 | A) Chartkick | Rails 친화적, GNT_POP_PLAN.md 지정 |
| SPC 계산 | A) Controller에서 직접 / B) Service Object | B) Service Object | Fat Model, Skinny Controller 원칙 |
| 불량분석 쿼리 | A) Controller에서 직접 / B) Service Object | B) Service Object | 복잡한 집계 쿼리를 분리하여 테스트 용이 |

### 6.3 구현 구조

```
app/
├── controllers/
│   └── quality/
│       ├── inspections_controller.rb        # (신규) 검사결과 CRUD
│       ├── defect_analysis_controller.rb    # (신규) 불량분석 차트
│       └── spc_controller.rb               # (신규) SPC 관리도
├── models/
│   ├── inspection_result.rb                 # (신규) 검사결과 모델
│   └── inspection_item.rb                   # (신규) 검사항목 모델
├── services/
│   ├── spc_calculator_service.rb            # (신규) SPC 계산
│   └── defect_analysis_service.rb           # (신규) 불량분석 쿼리
├── views/
│   └── quality/
│       ├── inspections/                     # (신규) 검사결과 뷰 4개
│       ├── defect_analysis/                 # (신규) 불량분석 뷰 1개
│       └── spc/                             # (신규) SPC 뷰 1개
├── config/
│   └── routes.rb                            # (수정) quality 네임스페이스 추가
└── views/layouts/
    └── _sidebar.html.erb                    # (수정) 메뉴 링크 연결
```

### 6.4 데이터 모델

```
inspection_results
├── id
├── lot_no (string, NOT NULL, index)
├── insp_type (integer, enum: incoming/process/outgoing)
├── insp_date (date, NOT NULL)
├── inspector_id (FK → workers, nullable)
├── result (integer, enum: pass/fail/conditional)
├── notes (text)
├── manufacturing_process_id (FK → manufacturing_processes, nullable)
└── timestamps

inspection_items
├── id
├── inspection_result_id (FK → inspection_results)
├── item_name (string, NOT NULL) - 예: "입력전압", "절연저항"
├── spec_value (string) - 예: "DC 450~850V"
├── measured_value (decimal) - 실측값
├── unit (string) - 예: "V", "MΩ"
├── judgment (integer, enum: pass/fail)
└── timestamps
```

---

## 7. 구현 순서

### Step 1: DB 마이그레이션 및 모델 (검사결과)
1. inspection_results 마이그레이션 생성
2. inspection_items 마이그레이션 생성
3. InspectionResult, InspectionItem 모델 생성
4. 시드 데이터 추가

### Step 2: 검사결과 CRUD (Quality::InspectionsController)
1. 라우트 추가 (`namespace :quality`)
2. 검사결과 목록 (index) - Ransack 검색
3. 검사결과 입력 (new/create) - 항목별 측정값 입력
4. 검사결과 상세 (show) - 항목별 판정 결과
5. 검사결과 수정/삭제 (edit/update/destroy)
6. 사이드바 "검사결과" 메뉴 링크 연결

### Step 3: 불량분석 (Quality::DefectAnalysisController)
1. DefectAnalysisService 생성 (집계 쿼리)
2. 불량분석 대시보드 (index)
3. 파레토 차트 (Chartkick)
4. 공정별/제품별 비교 차트
5. 일별 추이 차트
6. 사이드바 "불량분석" 메뉴 링크 연결

### Step 4: SPC 관리도 (Quality::SpcController)
1. SpcCalculatorService 생성 (X-bar R, Cp, Cpk 계산)
2. SPC 대시보드 (index)
3. X-bar 관리도 차트
4. R 관리도 차트
5. Cp/Cpk 표시 카드
6. 사이드바 "SPC" 메뉴 링크 연결

---

## 8. 의존성

### 8.1 Gem 의존성

| Gem | 용도 | 상태 |
|-----|------|------|
| chartkick | 차트 라이브러리 | 확인 필요 |
| groupdate | 날짜별 그룹 쿼리 | 확인 필요 |

### 8.2 기존 기능 의존성

| 의존 기능 | 용도 | 상태 |
|----------|------|------|
| production_results | LOT 번호 연동 | 구현 완료 |
| defect_records | 불량 데이터 소스 | 구현 완료 |
| defect_codes | 불량유형 마스터 | 구현 완료 |
| manufacturing_processes | 공정별 분석 | 구현 완료 |
| workers | 검사자 참조 | 구현 완료 |

---

## 9. 다음 단계

1. [ ] Design 문서 작성 (`quality-management.design.md`)
2. [ ] Gem 의존성 확인 (chartkick, groupdate)
3. [ ] 구현 시작

---

## 버전 이력

| 버전 | 날짜 | 변경 사항 | 작성자 |
|------|------|----------|--------|
| 0.1 | 2026-02-12 | 초안 작성 | GnT Dev Team |
