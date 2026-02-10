# GnT POP (Point of Production) System

(주)지앤티 생산현장 관리 시스템

## 개요

GnT POP는 컨버터, 변압기/인덕터, 전자부품, 회로기판 제조 현장을 위한 생산관리 시스템입니다.
실시간 생산현황 모니터링, 품질관리, LOT 추적 등의 기능을 제공합니다.

## 기술 스택

- **Framework**: Ruby on Rails 8.0
- **Ruby Version**: 3.3.x
- **Database**: SQLite3
- **Frontend**: Tailwind CSS v4, Hotwire (Turbo + Stimulus)
- **Background Jobs**: Solid Queue (Rails 8 기본)
- **Caching**: Solid Cache (Rails 8 기본)

## 주요 기능

### Phase 1: 기반 구축 ✅
- 사용자 인증 시스템 (Rails Authentication)
- 반응형 레이아웃 (사이드바 네비게이션)
- GnT CI 색상 테마 적용
- Hotwire 기본 설정

### Phase 5: 대시보드 (부분 완료)
- 메인 대시보드 UI (Partial 컴포넌트 분리)
- KPI 요약 카드 (생산량, 불량률, 설비 가동률, 작업지시)
- 공정별 생산 현황 모니터링
- 설비 상태 모니터링
- 최근 생산실적 테이블
- 알림 및 이벤트 표시

### 보안 및 품질
- 8시간 세션 만료 (공장 근무 시간 기준)
- 환경변수 기반 초기 사용자 설정
- 컨트롤러/모델 테스트 코드 작성

## 설치 및 실행

### 사전 요구사항

```bash
# Ruby 3.3.x 설치 (rbenv 사용 시)
rbenv install 3.3.0
rbenv global 3.3.0

# Node.js 설치 (Tailwind 빌드용)
# macOS: brew install node
```

### 설치

```bash
# 저장소 클론
cd /path/to/project
cd gnt_pop

# 의존성 설치
bundle install

# 데이터베이스 설정
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 실행

```bash
# 개발 서버 실행 (Tailwind 빌드 포함)
bin/dev

# 또는 Rails 서버만 실행
bin/rails server
```

서버 실행 후 http://localhost:3000 접속

## 로그인 정보

### 환경변수 설정 (권장)

```bash
# 관리자 계정 설정
export ADMIN_EMAIL="admin@example.com"
export ADMIN_PASSWORD="secure_password"

# 개발자 계정 설정 (개발 환경에서만)
export DEV_EMAIL="developer@example.com"
export DEV_PASSWORD="dev_password"

# 초기 사용자 생성
bin/rails db:seed
```

### 기본값 (개발 환경)

환경변수 미설정 시 개발 환경에서는 다음 기본값이 적용됩니다:
- 관리자: `admin@gnt.co.kr` / `password123`
- 개발자: `developer@gnt.co.kr` / `dev123456`

> **주의**: 프로덕션 환경에서는 반드시 `ADMIN_PASSWORD` 환경변수를 설정해야 합니다.

## 프로젝트 구조

```
gnt_pop/
├── app/
│   ├── assets/
│   │   └── tailwind/
│   │       └── application.css    # Tailwind CSS + GnT 테마
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── dashboard_controller.rb
│   │   └── sessions_controller.rb
│   ├── models/
│   │   ├── user.rb
│   │   └── session.rb
│   └── views/
│       ├── dashboard/
│       │   ├── index.html.erb          # 메인 대시보드
│       │   ├── _header.html.erb        # 페이지 헤더
│       │   ├── _kpi_cards.html.erb     # KPI 카드 섹션
│       │   ├── _process_status.html.erb  # 공정별 현황
│       │   ├── _equipment_status.html.erb # 설비 상태
│       │   ├── _recent_results.html.erb  # 최근 생산실적
│       │   └── _notifications.html.erb   # 알림 섹션
│       ├── layouts/
│       │   ├── application.html.erb
│       │   ├── _header.html.erb
│       │   └── _sidebar.html.erb
│       └── sessions/
│           └── new.html.erb       # 로그인 페이지
├── config/
│   ├── database.yml
│   └── routes.rb
└── db/
    ├── migrate/
    ├── schema.rb
    └── seeds.rb
```

## GnT 브랜드 색상

```css
--color-gnt-red: #E31837      /* 주요 포인트 색상 */
--color-gnt-black: #1A1A1A    /* 보조 색상 */
--color-gnt-dark-red: #B8132C /* 호버 상태 */
--color-gnt-light-red: #FF3D5A /* 밝은 포인트 */
```

## 디자인 원칙

- **60-30-10 색상 비율**: 화이트/슬레이트(60%), 슬레이트 중간톤(30%), GnT Red(10%)
- **터치스크린 최적화**: 큰 버튼, 터치 타겟 44px 이상
- **실시간 업데이트**: Turbo Streams를 통한 실시간 데이터 갱신

## 개발 현황

| Phase | 상태 | 설명 |
|-------|------|------|
| Phase 1: 기반 구축 | ✅ 완료 | 인증, 레이아웃, Tailwind 테마 |
| Phase 2: 기준정보 | ⬜ 대기 | 제품, 공정, 설비, 작업자 마스터 |
| Phase 3: 생산관리 | ⬜ 대기 | 작업지시, 생산실적, LOT 추적 |
| Phase 4: 품질관리 | ⬜ 대기 | 검사, 불량관리, SPC |
| Phase 5: 대시보드 | 🔄 진행중 | UI 완료, Partial 분리, 테스트 작성 |

## 라이선스

Copyright © 2026 (주)지앤티. All rights reserved.

---

> **문서 작성일**: 2026-02-09
> **최종 수정일**: 2026-02-10
> **개발**: 신호테크놀로지 × Claude AI
