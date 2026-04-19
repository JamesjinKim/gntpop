# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Development server (Rails + Tailwind watch)
bin/dev

# Database setup / reset
bin/rails db:create db:migrate db:seed

# Run all tests
bin/rails test

# Run single test file
bin/rails test test/controllers/dashboard_controller_test.rb

# Tailwind CSS build (standalone, usually handled by bin/dev)
bin/rails tailwindcss:build

# Linting & Security
bin/rubocop
bin/brakeman
bin/bundler-audit
```

## Technology Stack

- **Rails 8.1.2** with Hotwire (Turbo + Stimulus), Importmap, Propshaft
- **Tailwind CSS v4** + SQLite3 + Solid Queue/Cache/Cable
- **Key gems**: pagy (43.x), ransack, chartkick, groupdate, prawn/prawn-table, barby, rqrcode

## Architecture Overview

### Namespace Structure

Controllers are organized into 4 namespaces matching the sidebar navigation:

| Namespace | Purpose | Controllers |
|-----------|---------|-------------|
| `Masters::` | Master data CRUD | Products, ManufacturingProcesses, Equipments, Workers, DefectCodes |
| `Productions::` | Production management | WorkOrders, ProductionResults, LotTracking |
| `Quality::` | Quality control | Inspections, DefectAnalysis, Spc |
| `Monitoring::` | Real-time displays | ProductionBoard, EquipmentStatus |

Root controller: `DashboardController` (KPI dashboard at `/`)

### Service Objects (`app/services/`)

Business logic is extracted into service objects:
- `LotGeneratorService` - LOT number generation (format: `YYYYMMDD-XXX`)
- `WorkOrderCodeGeneratorService` - Work order code generation
- `DashboardQueryService` - Dashboard KPI aggregation
- `DefectAnalysisService` - Defect pareto/trend analysis
- `SpcCalculatorService` - SPC control chart calculations
- `EquipmentStatusService` - Equipment status aggregation

### Layouts

- `application.html.erb` - Main layout with sidebar (`_sidebar.html.erb`) + header (`_header.html.erb`)
- `fullscreen.html.erb` - Monitoring pages (no sidebar, auto-refresh)

### Stimulus Controllers

- `auto_refresh_controller` - Periodic page refresh for monitoring screens
- `clock_controller` - Real-time clock display
- `flash_controller` - Auto-dismissing flash messages

## Known Gotchas

### Model Column Naming Inconsistency

Most models use prefixed column names (`equipment_code`, `equipment_name`, `process_code`, `process_name`), but two models use generic names:

| Model | Code column | Name column |
|-------|-------------|-------------|
| Worker | `employee_number` | `name` |
| DefectCode | `code` | `name` |

### Equipment Table Name

Rails inflects "equipment" as uncountable. The model explicitly sets:
```ruby
self.table_name = "equipments"
```
Foreign key references require: `foreign_key: { to_table: :equipments }`

### Pagy v9+ (43.x)

- `Pagy::DEFAULT` hash is frozen - pass options per call: `pagy(@records, limit: 20)`
- `series` method is protected - use `page`, `pages`, `previous`, `next` public methods for custom pagination
- `require "pagy/extras/overflow"` is unnecessary (built-in)

### Tailwind CSS v4

- `@apply` with custom classes is NOT supported. Use native CSS properties.
- Dynamic class interpolation (`bg-#{color}-100`) doesn't work. Use `case/when` with static class strings.
- Brand colors defined in `app/assets/tailwind/application.css` via `@theme { --color-gnt-red: #E31837; --color-gnt-black: #1A1A1A; }`

### Authentication

Uses Rails 8 built-in authentication. Concern at `app/controllers/concerns/authentication.rb`.
Admin seed (dev default, per `db/seeds.rb`): `admin@gnt.co.kr` / `password123`, `developer@gnt.co.kr` / `dev123456`. Override with `ADMIN_EMAIL`/`ADMIN_PASSWORD` env vars.

## Design System

- **60-30-10 color ratio**: White/slate (60%), slate mid-tones (30%), GnT Red `#E31837` (10%)
- **Touch-optimized**: Minimum 44px touch targets for factory floor use
- Shared partials in `app/views/shared/`: `_pagination`, `_flash_messages`, `_empty_state`

## Project Context

Manufacturing POP (Point of Production) system for GnT (converter, transformer/inductor manufacturing). See `GNT_POP_PLAN.md` for full specs and `GNT_POP_MVP_CHECKLIST.md` for progress tracking.

# 답변은 항상 한글로 할것!
# 코드는 Clean Code 원칙을 준수할 것!
