# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 테스트 사용자 생성
if Rails.env.development?
  User.find_or_create_by!(email_address: "admin@gnt.co.kr") do |user|
    user.password = "password123"
    puts "Created admin user: admin@gnt.co.kr / password123"
  end
end
