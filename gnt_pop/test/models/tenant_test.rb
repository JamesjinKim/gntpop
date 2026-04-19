require "test_helper"

# 테넌트 모델 테스트 (Factory Box 멀티테넌시 Level 1)
class TenantTest < ActiveSupport::TestCase
  test "should be valid with code and name" do
    tenant = Tenant.new(code: "acme", name: "ACME Corp")
    assert tenant.valid?, tenant.errors.full_messages.to_sentence
  end

  test "requires code" do
    tenant = Tenant.new(name: "NoCode")
    assert_not tenant.valid?
    assert tenant.errors[:code].any?
  end

  test "requires name" do
    tenant = Tenant.new(code: "nocompany")
    assert_not tenant.valid?
    assert tenant.errors[:name].any?
  end

  test "code must be unique" do
    Tenant.create!(code: "unique_test", name: "Test Co")
    duplicate = Tenant.new(code: "unique_test", name: "Another Co")
    assert_not duplicate.valid?
    assert duplicate.errors[:code].any?
  end

  test "code format: lowercase alphanumeric/dash/underscore only" do
    invalid = Tenant.new(code: "Bad Code!", name: "Bad")
    assert_not invalid.valid?
    assert invalid.errors[:code].any?
  end

  test "gnt fixture exists" do
    assert_equal "gnt", tenants(:gnt).code
    assert tenants(:gnt).active?
  end

  test "active scope returns only active tenants" do
    Tenant.create!(code: "inactive_test", name: "Inactive", active: false)
    active_codes = Tenant.active.pluck(:code)
    assert_includes active_codes, "gnt"
    assert_not_includes active_codes, "inactive_test"
  end
end
