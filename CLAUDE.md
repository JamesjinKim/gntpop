# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This repository contains two main parts:
- **Root (`/`)**: Project documentation (planning, vision, checklists)
- **`gnt_pop/`**: Rails 8 application for manufacturing POP (Point of Production) system

## Common Commands

All commands should be run from the `gnt_pop/` directory:

```bash
cd gnt_pop

# Development server (Rails + Tailwind watch)
bin/dev

# Rails server only
bin/rails server

# Tailwind CSS build
bin/rails tailwindcss:build

# Database setup
bin/rails db:create db:migrate db:seed

# Run tests
bin/rails test

# Run single test file
bin/rails test test/controllers/dashboard_controller_test.rb

# Security audits
bin/brakeman
bin/bundler-audit

# Linting
bin/rubocop
```

## Technology Stack

- **Ruby on Rails 8.0** with Hotwire (Turbo + Stimulus)
- **Tailwind CSS v4** - Note: `@apply` with custom classes is NOT supported in v4. Use native CSS properties instead.
- **SQLite3** for database
- **Solid Queue/Cache/Cable** for background jobs, caching, and WebSockets

## Key Architecture Decisions

### Authentication
Uses Rails 8 built-in authentication generator. Authentication concern is in `app/controllers/concerns/authentication.rb`.

### Tailwind CSS Theme
GnT brand colors are defined in `app/assets/tailwind/application.css` using `@theme` block:
```css
@theme {
  --color-gnt-red: #E31837;
  --color-gnt-black: #1A1A1A;
}
```

### Design System
- **60-30-10 color ratio**: White/slate (60%), slate mid-tones (30%), GnT Red (10%)
- **Touch-optimized**: Minimum 44px touch targets for factory floor use

### Layout Structure
- `app/views/layouts/application.html.erb` - Main layout with sidebar
- `app/views/layouts/_sidebar.html.erb` - Navigation sidebar
- `app/views/layouts/_header.html.erb` - Top header

## Project Context

This is a manufacturing POP system for GnT (컨버터, 변압기/인덕터 제조). The system covers:
- Production tracking with LOT management
- Quality inspection and defect tracking
- Equipment status monitoring
- Real-time dashboard with KPIs

Refer to project documents for detailed requirements:
- `GNT_POP_PLAN.md` - Development plan and specifications
- `GNT_POP_MVP_CHECKLIST.md` - Implementation checklist
- `GNT_POP_VISION.md` - DX/AX transformation vision

# 답변은 항상 한글로 할것!
# 코드는 Clean Code 원칙을 준수할 것!