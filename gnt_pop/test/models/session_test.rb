require "test_helper"

# 세션 모델 테스트
# 사용자와의 관계 및 기본 기능을 확인합니다
class SessionTest < ActiveSupport::TestCase
  # 세션은 사용자에 속해야 합니다
  test "should belong to user" do
    session = sessions(:one)
    assert_respond_to session, :user
    assert_not_nil session.user
  end

  # 세션은 사용자 없이 생성될 수 없습니다
  test "should require user" do
    session = Session.new
    assert_not session.valid?
  end

  # 사용자의 세션을 생성할 수 있어야 합니다
  test "should create session for user" do
    user = users(:one)
    session = user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1")
    assert session.persisted?
    assert_equal user, session.user
  end
end
