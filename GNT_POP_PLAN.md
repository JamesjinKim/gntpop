# (주)지앤티 생산시점관리(POP) 시스템 개발 계획서

## 1. 기업 분석

### 1.1 기업 개요

| 항목 | 내용 |
|------|------|
| 회사명 | (주)지앤티 (GnT Co., Ltd.) |
| 대표이사 | 손일수 |
| 설립일 | 2022년 12월 |
| 사업분야 | 전기 상용차용 모빌리티 부품 개발 및 제조 |
| 본사 | 충남 아산시 탕정면 선문로254번길 12, 307-2호 |
| R&D센터 | 충남 천안시 서북구 천안천4길 32, GST 502호 |
| 인증 | ISO 9001 (품질), ISO 14001 (환경), ISO 45001 (안전보건) |
| 사업자번호 | 410-87-11796 |

### 1.2 연혁

- **2022.12** — GnT 법인 설립
- **2023.05** — 중소벤처기업부 슈퍼갭 스타트 1000+ 연구사업 선정
- **2023.10** — 이노스타 챌린지 수상
- **2023.11** — ISO 9001/14001/45001 획득, R&D 센터 구축
- **2024.05** — TIPA 디딤돌 연구사업 선정

### 1.3 생산 제품 라인업 분석

지앤티는 전기 상용차(버스, 트럭 등)에 탑재되는 전력변환 핵심부품을 생산합니다.

#### 제품 1: Converter (컨버터)
- **용도**: 전기차 배터리 전압을 차량 보조장치(12V/24V) 전원으로 변환
- **종류**: OBC (On-Board Charger) + LDC (Low-voltage DC-DC Converter) = IDC (Integrated DC Converter)
- **핵심 기능**: AC→DC 변환, 회생제동 시스템 핵심 부품
- **생산 공정**: PCB 조립 → 파워모듈 조립 → 하우징 결합 → 검사

#### 제품 2: Transformer Inductor (트랜스포머 인덕터)
- **용도**: 컨버터/인버터 내부의 전력변환 핵심 자성부품
- **종류**: 고주파 트랜스포머, 파워 인덕터
- **핵심 기능**: 전력변환 시 에너지 저장 및 전달
- **생산 공정**: 코어 조립 → 권선(와인딩) → 함침/경화 → 특성검사

#### 제품 3: Electronic Component (전자부품)
- **용도**: 전기차 전력회로의 필수 구성부품
- **특징**: 배터리 전류변환 핵심부품, 전자동 생산라인 보유
- **종류**: 파워 반도체, 커패시터, 저항 등 수동/능동 소자
- **생산 공정**: 자동 SMT 실장 → 검사 → 패키징

#### 제품 4: Circuit Board (회로기판)
- **용도**: 컨버터/인버터의 제어 및 전력 기판
- **종류**: PCB/PCBA (인쇄회로기판 어셈블리)
- **생산 공정**: SMT 실장 → 리플로우 → AOI검사 → 수삽 → 웨이브 솔더링 → 기능검사

---

## 2. 제조 공정 흐름도 (추정)

```
[자재 입고] → [자재 검수/입고검사]
       ↓
[자재 불출] → [공정 1: SMT/자동실장]
                    ↓
              [공정 2: 수삽/수작업조립]
                    ↓
              [공정 3: 솔더링(리플로우/웨이브)]
                    ↓
              [공정 4: 코어조립/권선(인덕터)]
                    ↓
              [공정 5: 함침/경화처리]
                    ↓
              [공정 6: 하우징조립/최종조립]
                    ↓
              [공정 7: 전기적 특성검사]
                    ↓
              [공정 8: 출하검사/포장]
                    ↓
              [완제품 입고] → [출하]
```

---

## 3. POP 시스템 설계

### 3.1 시스템 아키텍처

**Ruby on Rails 8 기반 3-Tier 웹 아키텍처**를 채택합니다. 웹 기반 시스템으로 별도 설치 없이 브라우저만으로 POP 단말, 사무실 PC, 모바일에서 접근 가능하며, Hotwire(Turbo + Stimulus)를 활용하여 SPA 수준의 실시간 사용자 경험을 제공합니다.

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Tier                         │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐ │
│  │ 웹 브라우저 │  │ 모바일 앱  │  │ POP 단말  │  │ 대시보드  │ │
│  │ (Hotwire) │  │ (PWA/API) │  │ (Kiosk)   │  │ (Turbo)   │ │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘ │
└────────┼──────────────┼──────────────┼──────────────┼───────┘
         └──────────────┴──────────────┴──────────────┘
                               │ HTTPS
┌──────────────────────────────┴──────────────────────────────┐
│                    Application Tier                          │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                   Ruby on Rails 8                       │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │ │
│  │  │ Controllers  │  │   Services   │  │    Jobs      │  │ │
│  │  │ (API/HTML)   │  │ (비즈니스)    │  │ (Solid Queue)│  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │ │
│  │  │   Models     │  │  Hotwire     │  │  ActionCable │  │ │
│  │  │ (Active Rec) │  │ (Turbo/Stim) │  │ (WebSocket)  │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────┴──────────────────────────────┐
│                      Data Tier                               │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐    │
│  │  PostgreSQL   │  │  Solid Cache  │  │  Solid Queue  │    │
│  │  (메인 DB)     │  │  (캐시)        │  │  (작업 큐)     │    │
│  └───────────────┘  └───────────────┘  └───────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

#### 3-Tier 아키텍처 장점

| 구분 | 설명 |
|------|------|
| **확장성** | 웹/모바일/키오스크 동시 지원, 멀티 사업장 확장 용이 |
| **접근성** | 브라우저만 있으면 어디서나 접근, 별도 설치 불필요 |
| **실시간** | ActionCable + Turbo Streams로 생산현황 실시간 갱신 |
| **유지보수** | 서버 업데이트만으로 전체 클라이언트 반영 |
| **비용** | Redis 없이 Solid Queue/Cache로 단일 서버 운영 가능 |

#### Rails 8 핵심 기능 활용

```
┌─────────────────────────────────────────────────────────────┐
│                     Rails 8 Features                         │
├─────────────────────────────────────────────────────────────┤
│  Hotwire (Turbo + Stimulus)                                  │
│  └─ 페이지 새로고침 없이 실시간 UI 업데이트                      │
│  └─ 생산실적 입력 시 대시보드 자동 갱신                          │
│                                                              │
│  Solid Queue (Redis 대체)                                    │
│  └─ 백그라운드 작업: 보고서 생성, 알림 발송                       │
│  └─ DB 기반으로 외부 의존성 제거                                │
│                                                              │
│  Solid Cache (Redis 대체)                                    │
│  └─ 대시보드 KPI 데이터 캐싱                                   │
│  └─ DB 기반 캐시로 운영 단순화                                 │
│                                                              │
│  Rails 8 Authentication                                      │
│  └─ 내장 인증 시스템으로 사용자/권한 관리                         │
│                                                              │
│  Kamal 2 (배포)                                              │
│  └─ Docker 기반 무중단 배포                                   │
│  └─ 단일 명령으로 프로덕션 배포                                 │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 핵심 모듈 구성

#### 모듈 A: 기준정보 관리
- 제품 마스터 (Converter, Transformer Inductor, Electronic Component, Circuit Board)
- BOM (Bill of Materials) 관리
- 공정 마스터 (공정코드, 공정명, 표준시간)
- 설비 마스터 (설비코드, 설비명, 공정 매핑)
- 작업자 마스터 (사원번호, 이름, 담당공정)
- 불량유형 코드 관리

#### 모듈 B: 생산관리
- **작업지시**: 생산계획 기반 작업지시서 발행 (제품별, 라인별)
- **작업 시작/종료**: 바코드 스캔으로 작업자-설비-자재 매핑
- **생산실적 수집**: 공정별 양품/불량 수량 실시간 입력
- **LOT 추적**: 제조번호 기반 이력추적 (자동차 부품 필수)

#### 모듈 C: 품질관리
- **수입검사**: 자재 입고 시 검사성적서 관리
- **공정검사**: 공정별 검사항목 체크 (전압, 전류, 절연저항 등)
- **출하검사**: 최종 전기적 특성검사 결과 기록
- **불량분석**: 불량유형별 파레토 분석, 공정능력(Cpk) 관리
- **SPC**: 통계적 공정관리 차트 (X-bar R 관리도)

#### 모듈 D: 설비관리
- 설비 가동/비가동 상태 모니터링
- 가동률 집계 (일/주/월)
- 예방보전 스케줄 관리
- 고장이력 관리

#### 모듈 E: 실시간 모니터링 (대시보드)
- 라인별 생산 현황 (목표 대비 실적) — **Turbo Streams 실시간 갱신**
- 불량률 실시간 추이 — **Chartkick 차트**
- 설비 가동 상태 표시 (Green/Yellow/Red) — **ActionCable 실시간 상태**
- 일일 생산 KPI 대시보드

---

## 4. Rails 프로젝트 구조 설계

### 4.1 디렉토리 구조

```
gnt_pop/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── dashboard_controller.rb        # 대시보드 (홈)
│   │   ├── sessions_controller.rb         # 로그인/로그아웃
│   │   ├── productions/
│   │   │   ├── work_orders_controller.rb  # 작업지시
│   │   │   ├── work_inputs_controller.rb  # 생산실적입력
│   │   │   └── work_histories_controller.rb # 생산이력조회
│   │   ├── quality/
│   │   │   ├── inspections_controller.rb  # 검사입력
│   │   │   ├── defects_controller.rb      # 불량관리
│   │   │   └── spc_controller.rb          # SPC 분석
│   │   ├── equipment/
│   │   │   ├── statuses_controller.rb     # 설비상태
│   │   │   └── maintenances_controller.rb # 보전관리
│   │   ├── masters/
│   │   │   ├── products_controller.rb     # 제품 마스터
│   │   │   ├── processes_controller.rb    # 공정 마스터
│   │   │   ├── equipments_controller.rb   # 설비 마스터
│   │   │   ├── workers_controller.rb      # 작업자 마스터
│   │   │   └── defect_codes_controller.rb # 불량코드 마스터
│   │   ├── reports/
│   │   │   ├── daily_controller.rb        # 일일 보고서
│   │   │   └── monthly_controller.rb      # 월간 보고서
│   │   └── api/
│   │       └── v1/                        # API 엔드포인트 (모바일/외부 연동)
│   │
│   ├── models/
│   │   ├── user.rb                        # 사용자 (Rails 8 Auth)
│   │   ├── product.rb                     # 제품 마스터
│   │   ├── manufacturing_process.rb       # 공정 마스터
│   │   ├── equipment.rb                   # 설비 마스터
│   │   ├── worker.rb                      # 작업자 마스터
│   │   ├── defect_code.rb                 # 불량코드 마스터
│   │   ├── work_order.rb                  # 작업지시
│   │   ├── production_result.rb           # 생산실적
│   │   ├── inspection_result.rb           # 검사결과
│   │   ├── defect_record.rb               # 불량이력
│   │   └── equipment_log.rb               # 설비 가동이력
│   │
│   ├── services/                          # 비즈니스 로직 (Service Objects)
│   │   ├── lot_generator_service.rb       # LOT 번호 생성
│   │   ├── spc_calculator_service.rb      # SPC 계산 (Cpk, X-bar R)
│   │   ├── report_generator_service.rb    # PDF 보고서 생성
│   │   └── equipment_monitor_service.rb   # 설비 상태 모니터링
│   │
│   ├── jobs/                              # Solid Queue 백그라운드 작업
│   │   ├── daily_report_job.rb            # 일일 보고서 자동 생성
│   │   ├── equipment_alert_job.rb         # 설비 이상 알림
│   │   └── data_cleanup_job.rb            # 오래된 데이터 정리
│   │
│   ├── channels/                          # ActionCable (실시간 통신)
│   │   ├── production_channel.rb          # 생산현황 실시간 브로드캐스트
│   │   └── equipment_channel.rb           # 설비상태 실시간 브로드캐스트
│   │
│   ├── views/
│   │   ├── layouts/
│   │   │   ├── application.html.erb       # 메인 레이아웃
│   │   │   └── _sidebar.html.erb          # 사이드바 네비게이션
│   │   ├── dashboard/
│   │   ├── productions/
│   │   ├── quality/
│   │   ├── equipment/
│   │   ├── masters/
│   │   └── reports/
│   │
│   ├── javascript/
│   │   ├── application.js                 # Hotwire 진입점
│   │   └── controllers/                   # Stimulus 컨트롤러
│   │       ├── barcode_controller.js      # 바코드 스캔 처리
│   │       ├── chart_controller.js        # 차트 인터랙션
│   │       └── touch_input_controller.js  # 터치 최적화 입력
│   │
│   └── assets/
│       └── stylesheets/
│           ├── application.css            # Tailwind CSS
│           └── components/                # 컴포넌트 스타일
│
├── config/
│   ├── routes.rb                          # 라우팅 설정
│   ├── database.yml                       # PostgreSQL 설정
│   └── deploy.yml                         # Kamal 배포 설정
│
├── db/
│   ├── migrate/                           # 마이그레이션 파일
│   ├── seeds.rb                           # 초기 데이터
│   └── schema.rb
│
└── test/                                  # 테스트
    ├── models/
    ├── controllers/
    ├── services/
    └── system/                            # 시스템 테스트 (Capybara)
```

### 4.2 기술 스택

| 분류 | 기술 | 비고 |
|------|------|------|
| **프레임워크** | Ruby 3.3 + Rails 8.0 | 3-Tier 웹 애플리케이션 |
| **프론트엔드** | Hotwire (Turbo + Stimulus) | SPA 수준 반응성, JS 최소화 |
| **CSS** | Tailwind CSS 4.0 | 유틸리티 기반 스타일링 |
| **실시간** | ActionCable + Turbo Streams | WebSocket 기반 실시간 갱신 |
| **백그라운드** | Solid Queue | DB 기반 작업 큐 (Redis 불필요) |
| **캐싱** | Solid Cache | DB 기반 캐시 (Redis 불필요) |
| **인증** | Rails 8 Authentication | 내장 인증 시스템 |
| **DB** | SQLite | MVP 단계, 운영 확장 시 PostgreSQL 전환 가능 |
| **ORM** | Active Record | Rails 내장 ORM |
| **차트** | Chartkick + Chart.js | SPC, 생산현황 차트 |
| **PDF** | Prawn | PDF 보고서 생성 |
| **바코드** | barby + rqrcode | 바코드/QR 생성 |
| **배포** | Kamal 2 | Docker 기반 무중단 배포 |
| **테스트** | Minitest + Capybara | 단위/시스템 테스트 |
| **로깅** | Rails Logger + Lograge | 구조화 로깅 |

### 4.3 주요 Gem 목록

```ruby
# Gemfile

# Rails 8 Core
gem "rails", "~> 8.0"
gem "propshaft"                    # Asset Pipeline
gem "puma", ">= 6.0"               # Web Server

# Database
gem "sqlite3"                      # MVP 단계 (운영 확장 시 PostgreSQL 전환)

# Rails 8 Features
gem "solid_queue"                  # 백그라운드 작업
gem "solid_cache"                  # 캐싱
gem "turbo-rails"                  # Hotwire Turbo
gem "stimulus-rails"               # Hotwire Stimulus

# Frontend
gem "tailwindcss-rails"            # Tailwind CSS

# Charts & Reports
gem "chartkick"                    # 차트 라이브러리
gem "groupdate"                    # 날짜별 그룹화
gem "prawn"                        # PDF 생성
gem "prawn-table"                  # PDF 테이블

# Barcode
gem "barby"                        # 바코드 생성
gem "rqrcode"                      # QR코드 생성
gem "chunky_png"                   # 이미지 처리

# Authentication & Authorization
gem "bcrypt"                       # 패스워드 암호화

# Utilities
gem "pagy"                         # 페이지네이션
gem "ransack"                      # 검색 기능

# Deployment
gem "kamal"                        # Docker 배포

group :development, :test do
  gem "debug"
  gem "factory_bot_rails"
  gem "faker"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
```

---

## 5. 개발 로드맵

### Phase 1: 기반 구축
- Rails 8 프로젝트 생성
- 디렉토리 구조 설계 (MVC + Services)
- SQLite 설정 및 초기 마이그레이션
- Rails 8 Authentication 설정 (사용자/권한)
- 메인 레이아웃 구현 (사이드바 네비게이션 + 콘텐츠 영역)
- Tailwind CSS 테마 설정 (지앤티 CI 색상: 빨강+검정)
- Hotwire 기본 설정 (Turbo + Stimulus)

### Phase 2: 기준정보 모듈
- 제품 마스터 CRUD (4개 제품군)
- 공정 마스터 CRUD (8개 공정)
- 설비 마스터 CRUD
- 작업자 마스터 CRUD
- BOM 관리 화면
- 불량코드 마스터
- Ransack 검색 기능 적용

### Phase 3: 생산관리 핵심
- 작업지시 등록/조회
- 생산실적 입력 화면 (터치스크린 최적화 - Stimulus)
- LOT 번호 자동생성 서비스 (LotGeneratorService)
- 바코드 스캔 연동 (Stimulus 컨트롤러)
- 공정별 생산현황 조회
- Turbo Streams 실시간 갱신

### Phase 4: 품질관리
- 수입검사 입력
- 공정검사 입력 (전기적 특성: 전압/전류/절연저항)
- 출하검사 입력
- 불량유형별 집계 및 파레토 차트 (Chartkick)
- SPC 관리도 (X-bar R Chart) — SpcCalculatorService

### Phase 5: 대시보드 & 모니터링
- 실시간 생산현황 대시보드 (ActionCable + Turbo Streams)
- 설비 가동 상태 표시판 (Green/Yellow/Red)
- 일일/주간/월간 생산 KPI (Chartkick)
- 불량률 추이 차트
- 생산 보고서 PDF 출력 (Prawn)
- Solid Queue 백그라운드 보고서 생성

### Phase 6: 고도화 (지속)
- 설비 PLC/센서 연동 (외부 API 또는 MQTT)
- ERP 시스템 인터페이스 (REST API)
- PWA 지원 (오프라인 모드)
- 모바일 최적화 (반응형 + 터치 UI)
- Kamal 2 프로덕션 배포 자동화

---

## 6. DB 스키마 (Rails Migration)

### 핵심 테이블

```ruby
# db/migrate/001_create_products.rb
class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :product_code, null: false, index: { unique: true }  # 'CVT-001', 'TFI-001'
      t.string :product_name, null: false
      t.integer :product_group, null: false  # enum: converter, transformer_inductor, electronic_component, circuit_board
      t.text :spec
      t.string :unit, default: 'EA'
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end

# db/migrate/002_create_manufacturing_processes.rb
class CreateManufacturingProcesses < ActiveRecord::Migration[8.0]
  def change
    create_table :manufacturing_processes do |t|
      t.string :process_code, null: false, index: { unique: true }  # 'P010', 'P020'
      t.string :process_name, null: false   # SMT실장, 수삽조립, 솔더링
      t.integer :process_order, null: false
      t.decimal :std_cycle_time, precision: 10, scale: 2  # 표준 사이클타임(초)
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end

# db/migrate/003_create_equipments.rb
class CreateEquipments < ActiveRecord::Migration[8.0]
  def change
    create_table :equipments do |t|
      t.string :equipment_code, null: false, index: { unique: true }
      t.string :equipment_name, null: false
      t.references :manufacturing_process, foreign_key: true
      t.string :location
      t.integer :status, default: 0  # enum: idle, run, down, pm
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end

# db/migrate/004_create_workers.rb
class CreateWorkers < ActiveRecord::Migration[8.0]
  def change
    create_table :workers do |t|
      t.string :employee_number, null: false, index: { unique: true }
      t.string :name, null: false
      t.references :manufacturing_process, foreign_key: true
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end

# db/migrate/005_create_work_orders.rb
class CreateWorkOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :work_orders do |t|
      t.string :work_order_code, null: false, index: { unique: true }  # 'WO-20260208-001'
      t.references :product, null: false, foreign_key: true
      t.integer :order_qty, null: false
      t.date :plan_date, null: false
      t.integer :status, default: 0  # enum: plan, in_progress, completed, cancelled
      t.integer :priority, default: 5

      t.timestamps
    end

    add_index :work_orders, :plan_date
    add_index :work_orders, :status
  end
end

# db/migrate/006_create_production_results.rb
class CreateProductionResults < ActiveRecord::Migration[8.0]
  def change
    create_table :production_results do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :manufacturing_process, null: false, foreign_key: true
      t.references :equipment, foreign_key: true
      t.references :worker, foreign_key: true
      t.string :lot_no, null: false
      t.integer :good_qty, default: 0
      t.integer :defect_qty, default: 0
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end

    add_index :production_results, :lot_no
    add_index :production_results, :created_at
  end
end

# db/migrate/007_create_inspection_results.rb
class CreateInspectionResults < ActiveRecord::Migration[8.0]
  def change
    create_table :inspection_results do |t|
      t.string :lot_no, null: false
      t.integer :insp_type, null: false  # enum: incoming, process, outgoing
      t.references :manufacturing_process, foreign_key: true
      t.string :insp_item, null: false   # 전압, 전류, 절연저항
      t.decimal :spec_min, precision: 15, scale: 6
      t.decimal :spec_max, precision: 15, scale: 6
      t.decimal :measured_value, precision: 15, scale: 6
      t.integer :judgment  # enum: pass, fail
      t.references :worker, foreign_key: true

      t.timestamps
    end

    add_index :inspection_results, :lot_no
    add_index :inspection_results, :insp_type
  end
end

# db/migrate/008_create_defect_codes.rb
class CreateDefectCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :defect_codes do |t|
      t.string :code, null: false, index: { unique: true }
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end

# db/migrate/009_create_defect_records.rb
class CreateDefectRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :defect_records do |t|
      t.references :production_result, null: false, foreign_key: true
      t.references :defect_code, null: false, foreign_key: true
      t.integer :defect_qty, default: 1
      t.text :description

      t.timestamps
    end
  end
end
```

---

## 7. 지앤티 제품별 품질검사 항목 (추정)

### Converter (컨버터)

| 검사항목 | 단위 | 규격 예시 |
|----------|------|-----------|
| 입력전압 | V | DC 450~850V |
| 출력전압 | V | DC 12V ±0.5V / 24V ±1V |
| 변환효율 | % | ≥ 93% |
| 절연저항 | MΩ | ≥ 500MΩ (DC 500V) |
| 내전압 | kV | AC 2.5kV / 1min |
| 리플전압 | mV | ≤ 200mV |
| 동작온도 | °C | -40 ~ +85°C |

### Transformer Inductor (트랜스포머 인덕터)

| 검사항목 | 단위 | 규격 예시 |
|----------|------|-----------|
| 인덕턴스 | μH | 규격치 ±10% |
| DCR (직류저항) | mΩ | ≤ 규격치 |
| 절연저항 | MΩ | ≥ 100MΩ |
| 턴비 | — | 규격치 ±2% |
| 외관검사 | — | 크랙, 권선불량 없음 |

### Circuit Board (회로기판 PCBA)

| 검사항목 | 단위 | 규격 예시 |
|----------|------|-----------|
| AOI (자동광학검사) | — | 미삽, 오삽, 브릿지 |
| ICT (In-Circuit Test) | — | 부품값 측정 |
| FCT (기능검사) | — | 동작 시나리오 PASS |
| 외관검사 | — | 납볼, 들뜸, 소손 |

---

## 8. 바로 시작할 작업 (Phase 1)

Rails 8 프로젝트의 Phase 1 기반 구축을 바로 시작합니다.

### 8.1 macOS 개발 환경 설정 (Intel)

```bash
# 1. Homebrew 설치 (이미 설치되어 있다면 생략)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. 필수 패키지 설치 (SQLite는 macOS에 기본 포함)
brew install rbenv ruby-build node

# 3. Ruby 3.3 설치 (rbenv 사용)
rbenv install 3.3.0
rbenv global 3.3.0

# 4. 쉘 설정 (~/.zshrc 또는 ~/.bash_profile에 추가)
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
source ~/.zshrc

# 5. Ruby 버전 확인
ruby -v  # ruby 3.3.0 이상 확인

# 6. Rails 8 설치
gem install rails -v "~> 8.0"
```

### 8.2 프로젝트 생성 및 설정

1. **Rails 8 프로젝트 생성**
   ```bash
   rails new gnt_pop --css=tailwind --skip-jbuilder
   cd gnt_pop
   ```
   > SQLite는 Rails 기본 DB이므로 별도 옵션 불필요

2. **Gem 설치**
   ```bash
   bundle add solid_queue solid_cache chartkick groupdate prawn barby pagy ransack
   ```

3. **DB 설정 및 마이그레이션**
   ```bash
   rails db:create
   rails generate migration CreateProducts ...
   rails db:migrate
   ```

4. **Rails 8 Authentication 설정**
   ```bash
   rails generate authentication
   ```

5. **메인 레이아웃 구현**
   - 좌측 사이드바 네비게이션 + 우측 콘텐츠 영역
   - 지앤티 CI 색상(빨강+검정) Tailwind 테마

6. **Hotwire 설정**
   - Turbo Frames/Streams 기본 구성
   - Stimulus 컨트롤러 초기 설정

### 8.3 개발 서버 실행

```bash
# 개발 서버 실행
bin/dev

# 브라우저에서 접속
# http://localhost:3000
```

---

## 부록 A. POP vs MES 비교

### A.1 개념적 차이

| 구분 | POP (Point of Production)  | MES (Manufacturing Execution System) |
|------|---------------------------|--------------------------------------|
| **정의** | 생산시점 정보 수집 시스템     | 제조실행 통합관리 시스템 |
| **범위** | 현장 데이터 수집에 집중       | 생산 계획부터 실행, 품질, 물류까지 통합 |
| **위치** | MES의 하위 모듈 또는 독립 시스템 | ERP와 현장(Shop Floor) 사이 중간 계층 |
| **핵심 질문** | "무엇을 얼마나 만들었는가" | "어떻게 효율적으로 만들 것인가" |

### A.2 시스템 계층 구조

```
┌─────────────────────────────────────────────────────────────┐
│                         ERP                                 │
│         (경영계획, 재무, 구매, 판매, 인사)                         │
└─────────────────────────────┬───────────────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                         MES                                 │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ • 생산계획 수립/스케줄링 (APS 연계)                            ││
│  │ • 작업지시 배분 및 우선순위 최적화                              ││
│  │ • 자재/재공품(WIP) 추적                                     ││
│  │ • 설비 예지보전 (AI/ML 기반)                                 ││
│  │ • 품질 통합관리 (SPC, CAPA, 8D)                             ││
│  │ • 문서관리 (작업표준서, 도면)                                 ││
│  │ • 에너지 관리                                              ││
│  │ • KPI 분석 (OEE, MTBF, MTTR)                             ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │                 ★ POP (현재 설계) ★                       ││
│  │  • 작업지시 조회/시작/종료                                   ││
│  │  • 생산실적 입력 (양품/불량)                                 ││
│  │  • LOT 추적                                              ││
│  │  • 품질검사 입력                                           ││
│  │  • 설비 상태 모니터링                                        ││
│  │  • 실시간 대시보드                                          ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────┬───────────────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                    현장 (Shop Floor)                         │
│              PLC, 센서, 바코드 스캐너, 작업자                     │
└─────────────────────────────────────────────────────────────┘
```

### A.3 현재 POP에 없는 MES 핵심 기능

| 기능  | 설명   | MES에서의 역할 |
|------|------|----------------|
| **생산 스케줄링**    | 주문/납기 기반 자동 일정 수립    | APS(Advanced Planning & Scheduling) 연계 |
| **자재 추적 (WIP)** | 재공품 위치/수량 실시간 파악     | 공정간 이동, 대기 시간 관리 |
| **레시피 관리**      | 제품별 설비 파라미터 자동 설정   | 설비 연동 시 파라미터 다운로드 |
| **예지보전**        | 설비 고장 예측 (진동, 온도 분석) | AI/ML 기반 사전 알림 |
| **CAPA/8D**      | 불량 원인 분석 및 시정조치       | 품질 이슈 체계적 해결 프로세스 |
| **문서 관리**      | 작업표준서, 도면, 변경이력       | 현장에서 최신 문서 조회 |
| **OEE 분석**      | 가동률 × 성능 × 품질           | 설비 종합효율 심층 분석 |
| **ERP 연동**      | 양방향 실시간 인터페이스         | 재고, 구매, 원가 자동 반영 |

### A.4 현재 POP 설계의 위치

```
현재 설계 범위 (MVP):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[데이터 수집]     [실적 관리]      [품질 관리]      [모니터링]
  바코드 스캔   →  생산실적 입력  →  검사 입력    →  대시보드
  작업자 인식      LOT 추적         불량 기록       KPI 표시

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

향후 MES 확장 시 추가:
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

[계획]           [실행 최적화]     [품질 심화]      [연동]
  스케줄링    →   WIP 추적      →  CAPA/8D     →  ERP 연동
  APS 연계        레시피 관리       예지보전        SCM 연동
```

### A.5 POP → MES 발전 로드맵

| 단계       | 시스템        | 핵심 기능               | 비고 |
|-----------|-------------|-----------------------|------|
| **현재**   | POP (MVP)   | 생산실적, 품질검사, 대시보드 | 본 계획서 범위 |
| **확장 1** | POP+        | WIP 추적, OEE 분석, ERP 인터페이스 | 데이터 축적 후 |
| **확장 2** | 경량 MES     | 스케줄링, 문서관리, CAPA    | 생산량 증가 시 |
| **최종**   | Full MES    | 예지보전, APS 연계, AI 분석 | 스마트팩토리 단계 |

### A.6 핵심 요약

> **POP는 MES의 데이터 수집 계층**에 해당하며, 향후 MES로 확장할 때 핵심 데이터 인프라가 됩니다.
>
> POP 데이터가 충분히 축적되어야 스케줄링, OEE 분석, 예지보전 같은 MES 고급 기능을 구현할 수 있습니다.
>
> 따라서 현재 POP MVP 단계에서는 **정확한 데이터 수집**과 **안정적인 시스템 운영**에 집중하는 것이 중요합니다.

---

> **문서 작성일**: 2026-02-08
> **수정일**: 2026-02-09 (Rails 8 기반 3-Tier 아키텍처로 변경, POP vs MES 비교 추가)
> **작성**: 신호테크놀로지 × Claude AI
