class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_tenant

  private

  # 멀티테넌시: 인증된 사용자의 테넌트를 현재 요청 스코프로 설정
  # - 비인증 요청(로그인 페이지 등)은 Current.user가 nil이므로 tenant도 nil
  # - 인증 가드(Authentication concern)가 먼저 적용되므로 보호된 액션에서는 항상 tenant 존재
  def set_current_tenant
    Current.tenant = Current.user&.tenant
  end
end
