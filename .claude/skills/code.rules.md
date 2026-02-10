# Ruby on Rails 8 코드 규칙

## 언어 및 주석
- 모든 응답은 한글로 작성
- 초보자도 이해할 수 있는 자세한 한글 주석을 함수 단위로 작성

## Rails 컨벤션
- RESTful 라우팅 준수
- Fat Model, Skinny Controller 원칙
- Service Object 패턴으로 복잡한 비즈니스 로직 분리
- Concern으로 공통 기능 모듈화

## 코드 스타일
- RuboCop Rails Omakase 스타일 가이드 준수
- 메서드는 10줄 이내로 유지
- 클래스는 100줄 이내로 유지
- 매직 넘버 대신 상수 사용

## Hotwire (Turbo + Stimulus)
- 페이지 전체 리로드 대신 Turbo Frame/Stream 활용
- JavaScript는 Stimulus 컨트롤러로 작성
- data-turbo-* 속성 적극 활용

## Tailwind CSS v4
- `@apply`에서 커스텀 클래스 참조 불가 (v4 제한)
- `@theme` 블록에 커스텀 색상 정의
- 60-30-10 색상 비율 준수 (White/Slate 60%, Slate mid 30%, GnT Red 10%)

## 데이터베이스
- 마이그레이션에 `null: false`, `index: true` 명시
- N+1 쿼리 방지 (includes, eager_load 활용)
- 복잡한 쿼리는 scope로 정의

## 테스트
- 모델/컨트롤러 테스트 필수
- fixture 대신 factory 패턴 권장
- 시스템 테스트로 E2E 검증

## 보안
- Strong Parameters 필수
- CSRF 토큰 검증 유지
- SQL Injection 방지 (직접 문자열 삽입 금지)
