# GnT POP (Point of Production) System

> **상태**: Factory Box Track 1 피벗 진행 중 (In-place 단일 브랜치). GnT v1은 `gnt-v1-final` 태그(커밋 6f3b854)로 동결, 이후 작업은 `main`에서 계속.
> 상세: [PRD](docs/PRD.md) · [전략](docs/factory-box-strategy.md) · [실행 TODO](docs/factory-box-TODO.md)

(주)지앤티 컨버터/트랜스포머 제조 생산현장 관리 시스템. 기준정보·생산관리·품질관리·실시간 모니터링을 통합 제공.

## 기술 스택

- Ruby 3.3.10 / Rails 8.1.2 / PostgreSQL
- Hotwire (Turbo + Stimulus) + Tailwind CSS v4
- Solid Queue / Solid Cache / Solid Cable

## 주요 기능 (모두 구현 완료)

| Namespace | 기능 |
|---|---|
| `Masters::` | Product / ManufacturingProcess / Equipment / Worker / DefectCode |
| `Productions::` | WorkOrder / ProductionResult / LotTracking |
| `Quality::` | Inspection / DefectAnalysis / Spc |
| `Monitoring::` | ProductionBoard / EquipmentStatus |
| (root) | Dashboard (KPI, 실시간 현황) |

개발 가이드·주의사항: [CLAUDE.md](CLAUDE.md)

## 실행

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/dev                    # Rails + Tailwind watch
```

접속: http://localhost:3000

## 기본 계정 (개발, `db:seed` 기본값)

- 관리자: `admin@gnt.co.kr` / `password123`
- 개발자: `developer@gnt.co.kr` / `dev123456`

프로덕션은 `ADMIN_EMAIL`, `ADMIN_PASSWORD` 환경변수 필수 (미설정 시 admin 유저 미생성).

## 디자인 원칙

- 60-30-10 색상: 화이트/슬레이트 60%, 슬레이트 중간톤 30%, GnT Red `#E31837` 10%
- 터치 타겟 최소 44px (공장 현장)

## 라이선스

Copyright © 2026 (주)지앤티. All rights reserved.
