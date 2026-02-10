# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 환경변수에서 초기 사용자 정보를 가져옵니다
# 설정 방법:
#   export ADMIN_EMAIL="admin@example.com"
#   export ADMIN_PASSWORD="secure_password"
#
# 또는 .env 파일에 설정 (dotenv gem 사용 시)

# 관리자 사용자 생성
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@gnt.co.kr")
admin_password = ENV.fetch("ADMIN_PASSWORD") { Rails.env.development? ? "password123" : nil }

if admin_password.present?
  User.find_or_create_by!(email_address: admin_email) do |user|
    user.password = admin_password
    puts "Created admin user: #{admin_email}"
  end
else
  puts "Skipping admin user creation: ADMIN_PASSWORD environment variable not set"
end

# 개발 환경 추가 사용자
if Rails.env.development?
  dev_email = ENV.fetch("DEV_EMAIL", "developer@gnt.co.kr")
  dev_password = ENV.fetch("DEV_PASSWORD", "dev123456")

  User.find_or_create_by!(email_address: dev_email) do |user|
    user.password = dev_password
    puts "Created developer user: #{dev_email}"
  end
end
