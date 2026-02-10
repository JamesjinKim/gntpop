require "test_helper"

# 대시보드 컨트롤러 테스트
# 인증된 사용자만 접근 가능하며, 모든 KPI 데이터가 정상적으로 로드되는지 확인합니다
class DashboardControllerTest < ActionDispatch::IntegrationTest
  # 인증 없이 대시보드에 접근하면 로그인 페이지로 리다이렉트되어야 합니다
  test "should redirect to login when not authenticated" do
    get root_path
    assert_redirected_to new_session_path
  end

  # 인증된 사용자는 대시보드에 접근할 수 있어야 합니다
  test "should get index when authenticated" do
    sign_in_as(users(:one))
    get root_path
    assert_response :success
  end

  # 대시보드 페이지에 필수 요소들이 렌더링되어야 합니다
  test "should render dashboard with required elements" do
    sign_in_as(users(:one))
    get root_path

    # 페이지 제목 확인
    assert_select "h1", text: "생산 현황 대시보드"

    # KPI 카드 섹션 확인
    assert_select "div", text: /오늘의 생산량/
    assert_select "div", text: /불량률/
    assert_select "div", text: /설비 가동률/
    assert_select "div", text: /작업지시 현황/
  end

  # 공정별 생산 현황 섹션이 렌더링되어야 합니다
  test "should render process status section" do
    sign_in_as(users(:one))
    get root_path

    assert_select "h3", text: "공정별 생산 현황"
    # 8개 공정 확인
    assert_select "div", text: /슬리팅/
    assert_select "div", text: /권선/
    assert_select "div", text: /검사/
  end

  # 설비 상태 섹션이 렌더링되어야 합니다
  test "should render equipment status section" do
    sign_in_as(users(:one))
    get root_path

    assert_select "h3", text: "설비 상태"
    # 설비 상태 범례 확인
    assert_select "div", text: /가동/
    assert_select "div", text: /대기/
    assert_select "div", text: /PM/
  end

  # 최근 생산실적 테이블이 렌더링되어야 합니다
  test "should render recent results table" do
    sign_in_as(users(:one))
    get root_path

    assert_select "h3", text: "최근 생산실적"
    assert_select "th", text: "작업지시"
    assert_select "th", text: "공정"
    assert_select "th", text: "수량"
  end

  # 알림 섹션이 렌더링되어야 합니다
  test "should render notifications section" do
    sign_in_as(users(:one))
    get root_path

    assert_select "h3", text: "알림 및 이벤트"
  end
end
