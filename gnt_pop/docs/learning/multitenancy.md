# 멀티테넌시(Multi-tenancy) 개념 학습 노트

> **작성일**: 2026-04-19 (Sprint 1 1차 이터레이션 완료 직후)
> **맥락**: Factory Box 피벗 — GnT POP를 중소기업용 Mini MES + WDAQ SaaS로 진화
> **관련 커밋**: `cf7b2c7` (Tenant + User + Product 기본 멀티테넌시 도입)

## 1. 한 문장 정의

> **"하나의 SaaS 앱을 여러 회사가 공유하는데, 서로의 데이터는 절대 보이지 않게 하는 것"**

## 2. 테넌트(Tenant)란?

**테넌트 = 한 조직(회사) = 데이터 분리의 단위**

같은 Factory Box SaaS를 3개 회사가 쓴다고 가정해봅시다:

| Tenant | code | 업종 | 제품 예 | 근무자 |
|---|---|---|---|---|
| **#1 GnT** (현재 유일) | `gnt` | 컨버터/트랜스포머 | CVT-001, TFI-001 | 김철수, 이영희 |
| #2 ACME (가상) | `acme` | 전기자전거 | BAT-PACK-A, MOTOR-500W | 홍길동 |
| #3 XYZ (가상) | `xyz` | 가전제품 | LED-BOARD-01 | 박영수 |

### 결과로 나타나는 동작
- 김철수가 로그인 → 컨버터/트랜스포머 제품 7개만 보임
- 홍길동이 로그인 → **같은 화면, 같은 URL이지만** 배터리/모터 제품만 보임
- 박영수가 로그인 → LED-BOARD만 보임
- **서로의 데이터는 절대로 보이지 않음**

## 3. 왜 이게 필요한가?

| 이유 | 설명 |
|---|---|
| **Track 1 SaaS의 전제** | 여러 중소기업이 한 앱을 공유 → 테넌시 없으면 회사마다 앱 설치(더 비쌈) |
| **데이터 누출 방지** | GnT 제품을 ACME가 우연히라도 조회 불가 (비즈니스 신뢰) |
| **나중에 도입이 더 어려움** | 수십 테이블 쌓인 뒤 tenant_id 추가는 지옥. 지금 작을 때 도입 |
| **GnT가 먼저 시범** | GnT는 1호 테넌트(내부 레퍼런스). 2호 테넌트가 생길 때 구조가 준비돼 있어야 함 |

## 4. 물리적 저장 구조 (Level 1 방식)

Factory Box는 **Level 1 멀티테넌시** 채택: `tenant_id` 컬럼으로 구분, **하나의 DB 하나의 테이블**에 모든 테넌트 데이터가 섞여 저장됨.

```
┌─────────────────────────────────────────────────────┐
│ Factory Box SaaS (한 앱, 하나의 DB)                  │
├─────────────────────────────────────────────────────┤
│                                                      │
│  products 테이블 (물리적으로 하나)                    │
│  ┌────────┬─────────────┬──────────┐                │
│  │tenant_id│product_code │ name     │                │
│  ├────────┼─────────────┼──────────┤                │
│  │   1    │ CVT-001     │ 컨버터   │ ← GnT 김철수만 봄│
│  │   1    │ TFI-001     │ 트랜스   │ ← GnT 이영희만 봄│
│  │   2    │ BAT-PACK-A  │ 배터리   │ ← ACME 홍길동만  │
│  │   3    │ LED-BOARD   │ LED보드  │ ← XYZ 박영수만   │
│  └────────┴─────────────┴──────────┘                │
│                                                      │
│  for_tenant(Current.tenant) 한 줄로                  │
│  로그인한 회사 데이터만 자동 필터                     │
└─────────────────────────────────────────────────────┘
```

### 멀티테넌시 3가지 레벨 비교 (참고)

| 레벨 | 방식 | 격리 강도 | 운영 비용 | 채택 여부 |
|---|---|---|---|---|
| **Level 1** | 공유 DB + `tenant_id` 컬럼 | 낮음 (앱 버그에 취약) | 가장 저렴 | ✅ **채택** |
| Level 2 | 공유 DB + 테넌트별 스키마 | 중간 | 중간 | 나중에 고려 |
| Level 3 | 테넌트별 독립 DB | 높음 | 높음 | 엔터프라이즈 요구 시 |

## 5. 코드 레벨 구현 (현재 코드 기준)

### 5.1 Tenant 모델 (`app/models/tenant.rb`)
```ruby
class Tenant < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9_-]+\z/ }
  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
```

### 5.2 User belongs_to (`app/models/user.rb`)
```ruby
class User < ApplicationRecord
  belongs_to :tenant   # ← 이 한 줄로 User.tenant_id NOT NULL 필수화
  has_secure_password
  has_many :sessions, dependent: :destroy
end
```

### 5.3 Product 스코핑 + 자동할당 (`app/models/product.rb`)
```ruby
class Product < ApplicationRecord
  belongs_to :tenant

  # 로그인한 유저의 회사 데이터만 필터 (명시적 호출 필수)
  scope :for_tenant, ->(t) { where(tenant: t) }

  # 생성 시 tenant_id 자동 세팅 (누락 방지)
  before_validation :assign_current_tenant, on: :create

  private

  def assign_current_tenant
    self.tenant_id ||= Current.tenant&.id
  end
end
```

### 5.4 요청 스코프 세팅 (`app/controllers/application_controller.rb`)
```ruby
class ApplicationController < ActionController::Base
  include Authentication
  before_action :set_current_tenant

  private

  def set_current_tenant
    Current.tenant = Current.user&.tenant
  end
end
```

### 5.5 컨트롤러에서 사용 (`app/controllers/masters/products_controller.rb`)
```ruby
# 모든 조회에 for_tenant 반드시 포함
def index
  @q = Product.for_tenant(Current.tenant).ransack(params[:q])
  @pagy, @products = pagy(@q.result.order(created_at: :desc))
end

def set_product
  @product = Product.for_tenant(Current.tenant).find(params[:id])
  # ← 타 테넌트 제품 id로 접근 시도하면 RecordNotFound
end
```

## 6. 실제 동작 검증 (재현 가능한 데모)

```bash
bin/rails runner "
# 가상 ACME 테넌트 + 제품 추가
acme = Tenant.find_or_create_by!(code: 'acme_demo') { |t|
  t.name = 'ACME Electronics'; t.active = true
}
Current.tenant = acme
Product.find_or_create_by!(product_code: 'BAT-PACK-A') { |p|
  p.product_name = '배터리 팩 A형'; p.product_group = :electronic_component
}

# GnT로 조회
Current.tenant = Tenant.find_by(code: 'gnt')
puts 'GnT 제품 수: ' + Product.for_tenant(Current.tenant).count.to_s  # => 7

# ACME로 조회
Current.tenant = acme
puts 'ACME 제품 수: ' + Product.for_tenant(Current.tenant).count.to_s  # => 1

# 물리적 전체
puts '테이블 전체: ' + Product.count.to_s  # => 8

# 정리
Product.for_tenant(acme).destroy_all; acme.destroy
"
```

## 7. 테넌시 vs 접근 권한 vs 메뉴 제어 (매우 중요한 구분)

이 셋은 **완전히 다른 층**입니다. 자주 혼동되므로 정확히 구분하세요.

| 층 | 용어 | 답하는 질문 | 예시 | 현재 구현 |
|---|---|---|---|---|
| **L1. 테넌트 분리** | Multi-tenancy | 어느 **회사** 데이터? | GnT 데이터 vs ACME 데이터 격리 | ✅ 구현됨 (Sprint 1) |
| **L2. 역할 권한** | RBAC (Role-Based Access Control) | 같은 회사 내 누가 **무엇을 할 수 있나**? | 관리자 vs 작업자 vs 감사자 | ❌ 미구현 |
| **L3. 메뉴 접근 제어** | Authorization | 이 **메뉴/기능**을 쓸 수 있나? | 생산팀은 품질 메뉴 접근 불가 | ❌ 미구현 |

### 현재 상태의 한계
- **모든 로그인 유저**는 **모든 메뉴**에 접근 가능
- 하지만 각 메뉴에서 **자기 회사 데이터만** 보임
- GnT 관리자든 GnT 작업자든 같은 메뉴 + 같은 GnT 데이터 접근

### L2/L3이 필요한 가상 시나리오 (미구현)
> "김철수(작업자)는 생산실적만 등록 가능, 제품 마스터는 조회만"
> "이영희(품질팀장)만 SPC/불량분석 메뉴 접근"

이 건 별도 구현 필요:
- `User.role` 컬럼 (admin/operator/auditor 등)
- `before_action :authorize_role!` 헬퍼
- 라우트별 권한 매트릭스

Factory Box 전략상 **"유료 고객이 생기면"** 추가 과제. Sprint 1~4 범위에 없음.

## 8. 현재 구현 범위 (Sprint 1 1차 이터레이션 기준)

### ✅ 적용 완료
- `tenants` 테이블 + `Tenant` 모델
- `users.tenant_id` + `User.belongs_to :tenant`
- `products.tenant_id` + `Product.belongs_to :tenant` + `for_tenant` scope + 자동할당 callback
- `Current.tenant` + `ApplicationController#set_current_tenant`
- `Masters::ProductsController`의 index / set_product에 `for_tenant` 스코핑

### ❌ 아직 미적용 (Sprint 1 2차 이터레이션에서 확산 예정)
다음 테이블들은 **아직 tenant_id 없음** → 이론상 두 회사 데이터가 섞일 수 있음:

- `manufacturing_processes` (공정)
- `equipments` (설비)
- `workers` (작업자)
- `defect_codes` (불량코드)
- `work_orders` (작업지시)
- `production_results` (생산실적)
- `defect_records` (불량기록)
- `inspection_results` (검사결과)
- `inspection_items` (검사항목)
- `lot_sensor_snapshots` (WDAQ 스캐폴딩)

**이 모두에 tenant_id 확산이 완료돼야** 진정한 테넌트 격리 완성.

## 9. 설계 결정의 근거 (왜 이렇게 했나)

| 결정 | 선택 | 이유 |
|---|---|---|
| 스코핑 방식 | **명시적 `for_tenant` scope** (default_scope 미사용) | default_scope는 `.unscoped` 남용, eager_load 이슈, 테스트 fixture 혼란 등 함정 多. 2~3개 경험 후 재평가 |
| User-Tenant 관계 | **1:1** (`User.belongs_to :tenant`) | 1인 1회사. 단순. 2호 테넌트 + 크로스 테넌트 관리자 필요 시점에 Membership 테이블로 확장 가능 |
| tenant_id 자동 할당 | **before_validation callback** | 컨트롤러에서 수동 set 시 누락 위험. callback으로 100% 자동 |
| 마이그레이션 방식 | **3-in-1 안전 패턴**: add nullable → backfill → NOT NULL + FK restrict | 기존 데이터 무손상. 롤백 안전 |
| Tenant 스키마 범위 | **최소**: code, name, active | YAGNI. subdomain/logo_url 등은 2호 테넌트 실수요 시점에 추가 |
| 외래키 삭제 정책 | `on_delete: :restrict` | 실수로 Tenant 삭제하면 관련 데이터 동반 삭제 방지 |

## 10. 흔한 실수와 주의사항 (Known Pitfalls)

### 🚨 실수 1: for_tenant 호출 누락
```ruby
# 위험: 테넌트 분리 우회
@products = Product.all.order(:created_at)

# 올바름
@products = Product.for_tenant(Current.tenant).order(:created_at)
```
→ 컨트롤러에서 `for_tenant` 빠뜨리면 **전 테넌트 데이터 노출**. default_scope 아니므로 수동 호출 필수.

### 🚨 실수 2: 외부 id로 find
```ruby
# 위험: 다른 테넌트 제품 id 넣으면 그걸 찾아버림
@product = Product.find(params[:id])

# 올바름
@product = Product.for_tenant(Current.tenant).find(params[:id])
```
→ 뒤의 방식은 타 테넌트 id 접근 시 `RecordNotFound`.

### 🚨 실수 3: Current.tenant nil 상태에서 생성
```ruby
# Current.tenant가 nil이면 callback이 tenant_id=nil로 두고 저장 실패
Product.create!(...)  # ActiveRecord::RecordInvalid — tenant is required
```
→ 배치 작업/시드에서는 `Current.tenant = ...` 먼저 세팅 필요.

### 🚨 실수 4: 마이그레이션에서 기존 행 tenant_id 안 채우고 NOT NULL 전환
→ 에러. 반드시 3단계(nullable add → backfill → NOT NULL) 준수.

### 🚨 실수 5: 화면 간 숫자 불일치를 테넌시 버그로 오해
**실제 사례 (2026-04-20)**: ACME 로그인 시 대시보드 "오늘의 생산량=0", 불량분석 "총 생산수량=53". 테넌시 누출 의심 → 실측 결과 **기간 범위 차이**.

| 화면 | 기본 기간 | 용도 |
|---|---|---|
| 대시보드 | 오늘 하루 (`Date.current.all_day`) | 운영 현황 모니터링 |
| 불량분석 | 최근 30일 | 기간 추세 분석 |
| SPC | 최근 30일 | 관리도 |

→ **테넌시가 올바르게 동작해도 화면마다 집계 기간이 다르면 숫자가 다르게 나옴**. 이는 **버그가 아니라 설계**. 테넌시 격리 확인 시 혼동하지 말 것.

**해결**: 각 화면에 기간 라벨 명시 (`docs/learning/multitenancy.md` 기록 당시 `quality/defect_analysis`에 "조회 기간: YYYY-MM-DD ~ YYYY-MM-DD (N일간)" 라벨 추가). 테넌시 격리 검증 시에는 **같은 기간으로 맞춰서** 비교할 것.

## 11. 관련 파일 빠른 참조

- 모델: `app/models/tenant.rb`, `app/models/user.rb`, `app/models/product.rb`, `app/models/current.rb`
- 컨트롤러: `app/controllers/application_controller.rb` (before_action), `app/controllers/masters/products_controller.rb` (for_tenant 적용 예)
- 마이그레이션: `db/migrate/20260419223632_create_tenants.rb`, `20260419223633_add_tenant_to_users.rb`, `20260419223634_add_tenant_to_products.rb`
- 시드: `db/seeds.rb` (Tenant 먼저 생성)
- 테스트: `test/models/tenant_test.rb`, `test/models/user_test.rb`
- 전략 문서: `docs/factory-box-strategy.md` §멀티테넌시
- 실행 체크리스트: `docs/factory-box-TODO.md` Sprint 1

## 12. 더 읽을거리 (키워드 & 참고)

- **SaaS pattern**: Multi-tenancy in SaaS architecture
- **Rails gem**: `acts_as_tenant` — 자동화 + 검증 기능 제공 gem (현재 미도입, 2~3개 수동 확산 후 재평가 예정)
- **데이터 격리 레벨**: Shared Database / Shared Schema (Level 1), Shared DB / Separate Schema (Level 2), Separate DB (Level 3)
- **Row-level security (RLS)**: PostgreSQL의 DB 수준 격리 기능. Level 1에 추가 안전 장치로 사용 가능. 현재 미채택

## 13. 요약 카드 (한눈에)

- 테넌트 = **한 회사** = 데이터 분리 단위
- `tenant_id` 컬럼 + `for_tenant(Current.tenant)` scope = 자동 격리
- `Current.tenant`는 로그인한 유저의 `user.tenant`로 자동 세팅
- 테넌트 분리 ≠ 역할 권한 ≠ 메뉴 제어 (셋은 각기 다른 층)
- 현재 `Product` 한 테이블만 적용. 전체 테이블로 확산해야 진정한 격리 완성
