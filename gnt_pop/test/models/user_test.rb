require "test_helper"

# 사용자 모델 테스트
# 기본적인 유효성 검사 및 관계 설정을 확인합니다
class UserTest < ActiveSupport::TestCase
  # 이메일 주소가 소문자로 변환되고 공백이 제거되어야 합니다
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  # 유효한 사용자 객체는 저장되어야 합니다
  test "should be valid with valid attributes" do
    user = User.new(email_address: "test@example.com", password: "password123")
    assert user.valid?
  end

  # 비밀번호는 필수입니다 (has_secure_password 제공)
  test "should require password" do
    user = User.new(email_address: "test@example.com")
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  # 사용자는 여러 세션을 가질 수 있습니다
  test "should have many sessions" do
    user = users(:one)
    assert_respond_to user, :sessions
  end
end
