# (주)지앤티 POP MVP 개발 체크리스트

> **목적**: MVP(Minimum Viable Product) 개발 진행 상황을 추적하고 완료 여부를 확인
> **기준 문서**: GNT_POP_PLAN.md

---

## Phase 1: 기반 구축

### 1.1 개발 환경 설정
- [x] Homebrew 설치 확인
- [x] rbenv + ruby-build 설치
- [x] Ruby 3.3.x 설치 및 글로벌 설정
- [x] Node.js 설치 (Tailwind 빌드용)
- [x] Rails 8.0 설치
- [x] Git 저장소 초기화

### 1.2 Rails 프로젝트 생성
- [x] `rails new gnt_pop --css=tailwind --skip-jbuilder` 실행
- [x] 프로젝트 디렉토리 구조 확인
- [x] `.gitignore` 설정 확인
- [x] 초기 커밋 생성

### 1.3 Gem 설치 및 설정
- [x] solid_queue 추가 및 설정 (Rails 8 기본 포함)
- [x] solid_cache 추가 및 설정 (Rails 8 기본 포함)
- [x] chartkick + groupdate 추가
- [x] prawn (PDF) 추가
- [x] barby + rqrcode (바코드) 추가
- [x] pagy (페이지네이션) 추가
- [x] ransack (검색) 추가
- [x] `bundle install` 완료

### 1.4 데이터베이스 설정
- [x] SQLite 설정 확인 (config/database.yml)
- [x] `rails db:create` 실행
- [x] 초기 마이그레이션 파일 생성
- [x] `rails db:migrate` 실행

### 1.5 인증 시스템
- [x] `rails generate authentication` 실행
- [x] User 모델 확인
- [x] 로그인/로그아웃 기능 테스트
- [x] 세션 관리 확인

### 1.6 메인 레이아웃 구현
- [x] application.html.erb 레이아웃 구성
- [x] 사이드바 네비게이션 (_sidebar.html.erb)
- [x] 헤더 영역 (로고, 사용자 정보)
- [x] 메인 콘텐츠 영역
- [x] 반응형 레이아웃 (모바일 대응)

### 1.7 Tailwind CSS 테마
- [x] 지앤티 CI 색상 정의 (빨강 #E31837, 검정 #1A1A1A)
- [x] 커스텀 색상 팔레트 설정
- [x] 기본 버튼 스타일
- [x] 폼 요소 스타일
- [x] 테이블 스타일
- [x] 카드 컴포넌트 스타일

### 1.8 Hotwire 기본 설정
- [x] Turbo Drive 동작 확인
- [x] Turbo Frames 테스트
- [x] Turbo Streams 테스트
- [x] Stimulus 컨트롤러 기본 구조 생성

### 1.9 Phase 1 완료 확인
- [x] `bin/dev`로 개발 서버 실행
- [x] http://localhost:3000 접속 확인
- [x] 로그인 페이지 동작 확인
- [x] 사이드바 네비게이션 동작 확인
- [x] Git 커밋 및 태그 (v0.1.0-phase1)

---

## Phase 2: 기준정보 모듈

### 2.1 제품 마스터 (Products)
- [ ] Product 모델 생성 (마이그레이션)
- [ ] enum 정의 (product_group: converter, transformer_inductor, electronic_component, circuit_board)
- [ ] Products 컨트롤러 생성
- [ ] 목록 화면 (index)
- [ ] 등록 화면 (new/create)
- [ ] 수정 화면 (edit/update)
- [ ] 삭제 기능 (destroy)
- [ ] 검색 기능 (Ransack)
- [ ] 페이지네이션 (Pagy)

### 2.2 공정 마스터 (Manufacturing Processes)
- [ ] ManufacturingProcess 모델 생성
- [ ] 8개 공정 시드 데이터 작성
- [ ] CRUD 컨트롤러 및 뷰
- [ ] 공정 순서(process_order) 관리
- [ ] 표준 사이클타임 입력

### 2.3 설비 마스터 (Equipments)
- [ ] Equipment 모델 생성
- [ ] 공정과의 관계 설정 (belongs_to :manufacturing_process)
- [ ] enum 정의 (status: idle, run, down, pm)
- [ ] CRUD 컨트롤러 및 뷰
- [ ] 공정별 설비 필터링

### 2.4 작업자 마스터 (Workers)
- [ ] Worker 모델 생성
- [ ] 사원번호 유니크 검증
- [ ] 담당 공정 연결
- [ ] CRUD 컨트롤러 및 뷰

### 2.5 불량코드 마스터 (Defect Codes)
- [ ] DefectCode 모델 생성
- [ ] 불량코드 체계 정의
- [ ] CRUD 컨트롤러 및 뷰

### 2.6 BOM 관리 (선택)
- [ ] Bom 모델 설계
- [ ] 제품-자재 관계 설정
- [ ] BOM 등록 화면

### 2.7 Phase 2 완료 확인
- [ ] 모든 기준정보 CRUD 동작 확인
- [ ] 시드 데이터로 초기 데이터 입력
- [ ] 검색 및 페이지네이션 동작 확인
- [ ] Git 커밋 및 태그 (v0.2.0-phase2)

---

## Phase 3: 생산관리 핵심

### 3.1 작업지시 (Work Orders)
- [ ] WorkOrder 모델 생성
- [ ] enum 정의 (status: plan, in_progress, completed, cancelled)
- [ ] 작업지시 코드 자동생성 (WO-YYYYMMDD-NNN)
- [ ] 작업지시 등록 화면
- [ ] 작업지시 목록 (날짜별, 상태별 필터)
- [ ] 작업지시 상세 조회

### 3.2 생산실적 입력 (Production Results)
- [ ] ProductionResult 모델 생성
- [ ] 작업지시 선택 → 공정 선택 흐름
- [ ] 양품/불량 수량 입력 폼
- [ ] 터치스크린 최적화 UI (큰 버튼, 숫자 키패드)
- [ ] Stimulus 컨트롤러 (touch_input_controller.js)

### 3.3 LOT 추적
- [ ] LOT 번호 자동생성 서비스 (LotGeneratorService)
- [ ] LOT 형식 정의 (예: L-YYYYMMDD-PPPP-NNN)
- [ ] LOT별 이력 조회 화면
- [ ] LOT 라벨 출력 (바코드 포함)

### 3.4 바코드 스캔 연동
- [ ] barcode_controller.js (Stimulus) 생성
- [ ] USB HID 스캐너 입력 처리
- [ ] 작업지시 바코드 스캔 → 자동 조회
- [ ] 작업자 바코드 스캔 → 자동 인식

### 3.5 공정별 생산현황
- [ ] 공정별 실적 집계 쿼리
- [ ] 일별/주별/월별 조회
- [ ] 목표 대비 실적 표시

### 3.6 실시간 갱신 (Turbo Streams)
- [ ] ProductionChannel (ActionCable) 생성
- [ ] 생산실적 입력 시 대시보드 자동 갱신
- [ ] Turbo Stream 브로드캐스트 구현

### 3.7 Phase 3 완료 확인
- [ ] 작업지시 → 생산실적 입력 → 조회 흐름 테스트
- [ ] 바코드 스캔 동작 확인
- [ ] 실시간 갱신 확인
- [ ] Git 커밋 및 태그 (v0.3.0-phase3)

---

## Phase 4: 품질관리

### 4.1 검사결과 모델
- [ ] InspectionResult 모델 생성
- [ ] enum 정의 (insp_type: incoming, process, outgoing)
- [ ] enum 정의 (judgment: pass, fail)

### 4.2 수입검사
- [ ] 수입검사 입력 화면
- [ ] 자재 LOT 연결
- [ ] 검사 항목별 합격/불합격 판정

### 4.3 공정검사
- [ ] 공정검사 입력 화면
- [ ] 전기적 특성 입력 (전압, 전류, 절연저항)
- [ ] 규격 범위(spec_min, spec_max) 자동 판정
- [ ] 측정값 입력 UI (숫자 키패드)

### 4.4 출하검사
- [ ] 출하검사 입력 화면
- [ ] 최종 검사 체크리스트
- [ ] 출하 승인 처리

### 4.5 불량 기록 (Defect Records)
- [ ] DefectRecord 모델 생성
- [ ] 불량 유형 선택 (DefectCode 연결)
- [ ] 불량 수량 및 상세 기록
- [ ] 생산실적과 연결

### 4.6 불량 분석
- [ ] 불량유형별 집계
- [ ] 파레토 차트 (Chartkick)
- [ ] 기간별 불량률 추이

### 4.7 SPC (통계적 공정관리)
- [ ] SpcCalculatorService 생성
- [ ] X-bar R 차트 계산 로직
- [ ] Cpk 계산 로직
- [ ] SPC 차트 화면 (Chartkick)

### 4.8 Phase 4 완료 확인
- [ ] 검사 입력 → 판정 → 기록 흐름 테스트
- [ ] 불량 분석 차트 동작 확인
- [ ] SPC 차트 동작 확인
- [ ] Git 커밋 및 태그 (v0.4.0-phase4)

---

## Phase 5: 대시보드 & 모니터링

### 5.1 메인 대시보드
- [x] DashboardController 생성
- [x] 오늘의 생산 현황 위젯
- [x] 불량률 위젯
- [x] 설비 상태 위젯
- [x] 최근 알림/이벤트 위젯
- [x] 공정별 생산 현황 위젯
- [x] 최근 생산실적 테이블
- [x] 60-30-10 색상 비율 디자인 적용

### 5.2 실시간 생산현황
- [ ] 라인별 생산 현황 표시
- [ ] 목표 대비 실적 프로그레스 바
- [ ] ActionCable 실시간 업데이트
- [ ] 자동 새로고침 (Turbo Streams)

### 5.3 설비 상태 모니터링
- [ ] 설비 상태 표시판 (Green/Yellow/Red)
- [ ] EquipmentChannel (ActionCable)
- [ ] 설비 상태 변경 시 실시간 반영
- [ ] 설비 가동률 표시

### 5.4 KPI 차트
- [ ] 일별 생산량 차트 (Chartkick)
- [ ] 주별 생산량 차트
- [ ] 월별 생산량 차트
- [ ] 불량률 추이 차트
- [ ] 공정별 생산 비교 차트

### 5.5 보고서 생성
- [ ] ReportGeneratorService 생성
- [ ] 일일 생산 보고서 템플릿 (Prawn)
- [ ] PDF 다운로드 기능
- [ ] Solid Queue 백그라운드 생성

### 5.6 Phase 5 완료 확인
- [ ] 대시보드 모든 위젯 동작 확인
- [ ] 실시간 업데이트 확인
- [ ] PDF 보고서 생성 확인
- [ ] Git 커밋 및 태그 (v0.5.0-phase5)

---

## MVP 최종 검증

### 기능 테스트
- [ ] 전체 사용자 시나리오 테스트
  - [ ] 로그인 → 작업지시 조회 → 생산실적 입력 → 대시보드 확인
  - [ ] 품질검사 입력 → 불량 기록 → 분석 조회
  - [ ] 기준정보 등록/수정/삭제
- [ ] 바코드 스캔 실제 장비 테스트
- [ ] 터치스크린 UI 테스트 (태블릿)

### 성능 테스트
- [ ] 페이지 로딩 속도 확인 (< 2초)
- [ ] 대량 데이터 조회 테스트 (1000건 이상)
- [ ] 동시 접속 테스트 (3-5명)

### 보안 점검
- [ ] 인증 없이 접근 차단 확인
- [ ] CSRF 토큰 확인
- [ ] SQL Injection 방어 확인
- [ ] XSS 방어 확인

### 배포 준비
- [ ] 프로덕션 환경 설정 (config/environments/production.rb)
- [ ] 시크릿 키 설정
- [ ] 에셋 프리컴파일 테스트
- [ ] 데이터베이스 백업 스크립트

### 문서화
- [x] README.md 작성
- [ ] 사용자 매뉴얼 작성
- [ ] 관리자 가이드 작성

### MVP 완료
- [ ] 고객사 데모 진행
- [ ] 피드백 수집 및 정리
- [ ] Git 태그 (v1.0.0-mvp)
- [ ] MVP 완료 보고

---

## 진행 현황 요약

| Phase | 상태 | 시작일 | 완료일 | 비고 |
|-------|------|--------|--------|------|
| Phase 1: 기반 구축 | ✅ 완료 | 2026-02-09 | 2026-02-09 | v0.1.0-phase1 |
| Phase 2: 기준정보 | ⬜ 대기 | - | - | |
| Phase 3: 생산관리 | ⬜ 대기 | - | - | |
| Phase 4: 품질관리 | ⬜ 대기 | - | - | |
| Phase 5: 대시보드 | 🔄 진행중 | 2026-02-09 | - | 메인 대시보드 UI 완료, 60-30-10 디자인 적용 |
| MVP 최종 검증 | ⬜ 대기 | - | - | |

**상태 범례**: ⬜ 대기 | 🔄 진행중 | ✅ 완료

---

> **문서 작성일**: 2026-02-09
> **최종 수정일**: 2026-02-09
> **작성**: 신호테크놀로지 × Claude AI
