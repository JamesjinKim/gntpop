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

# ============================================================
# 생산 마스터 데이터
# ============================================================

puts "\n생산 마스터 데이터를 생성합니다..."

# 공정 마스터
puts "\n[1/5] 공정 마스터 생성 중..."
processes_data = [
  { process_code: "P010", process_name: "슬리팅", process_order: 1, std_cycle_time: 30 },
  { process_code: "P020", process_name: "권선", process_order: 2, std_cycle_time: 120 },
  { process_code: "P030", process_name: "조립", process_order: 3, std_cycle_time: 90 },
  { process_code: "P040", process_name: "몰딩/함침", process_order: 4, std_cycle_time: 180 },
  { process_code: "P050", process_name: "가공", process_order: 5, std_cycle_time: 60 },
  { process_code: "P060", process_name: "검사", process_order: 6, std_cycle_time: 45 },
  { process_code: "P070", process_name: "포장", process_order: 7, std_cycle_time: 20 },
  { process_code: "P080", process_name: "출하", process_order: 8, std_cycle_time: 15 }
]
processes_data.each do |data|
  ManufacturingProcess.find_or_create_by!(process_code: data[:process_code]) do |process|
    process.assign_attributes(data)
  end
end

# 제품 마스터
puts "[2/5] 제품 마스터 생성 중..."
products_data = [
  { product_code: "CVT-001", product_name: "OBC+LDC 통합 컨버터", product_group: :converter },
  { product_code: "CVT-002", product_name: "LDC 단독 컨버터", product_group: :converter },
  { product_code: "TFI-001", product_name: "고주파 트랜스포머 (3.3kW)", product_group: :transformer_inductor },
  { product_code: "TFI-002", product_name: "파워 인덕터 (100uH)", product_group: :transformer_inductor },
  { product_code: "ELC-001", product_name: "파워 반도체 모듈", product_group: :electronic_component },
  { product_code: "PCB-001", product_name: "메인 제어 PCBA", product_group: :circuit_board },
  { product_code: "PCB-002", product_name: "전력 변환 PCBA", product_group: :circuit_board }
]
products_data.each do |data|
  Product.find_or_create_by!(product_code: data[:product_code]) do |product|
    product.assign_attributes(data)
  end
end

# 불량코드
puts "[3/5] 불량코드 마스터 생성 중..."
defect_codes_data = [
  { code: "D01", name: "납볼 (Solder Ball)", description: "납 볼이 발생하여 쇼트 위험" },
  { code: "D02", name: "미납 (Insufficient)", description: "납 량이 부족한 상태" },
  { code: "D03", name: "쇼트 (Short)", description: "인접 패드간 납 브릿지" },
  { code: "D04", name: "크랙 (Crack)", description: "코어 또는 기판에 크랙 발생" },
  { code: "D05", name: "오삽 (Wrong Component)", description: "잘못된 부품이 실장됨" },
  { code: "D06", name: "미삽 (Missing)", description: "부품이 실장되지 않음" },
  { code: "D07", name: "들뜸 (Lifted)", description: "부품이 들려있는 상태" },
  { code: "D08", name: "특성불량 (Out of Spec)", description: "전기적 특성이 규격 벗어남" },
  { code: "D09", name: "외관불량 (Cosmetic)", description: "스크래치, 찍힘, 오염 등" },
  { code: "D10", name: "기타 (Others)", description: "기타 분류 불가 불량" }
]
defect_codes_data.each do |data|
  DefectCode.find_or_create_by!(code: data[:code]) do |defect_code|
    defect_code.assign_attributes(data)
  end
end

# 설비 마스터 (공정별 1~2대)
puts "[4/5] 설비 마스터 생성 중..."
slitting = ManufacturingProcess.find_by(process_code: "P010")
winding = ManufacturingProcess.find_by(process_code: "P020")
assembly = ManufacturingProcess.find_by(process_code: "P030")
molding = ManufacturingProcess.find_by(process_code: "P040")
machining = ManufacturingProcess.find_by(process_code: "P050")
inspection = ManufacturingProcess.find_by(process_code: "P060")
packing = ManufacturingProcess.find_by(process_code: "P070")
shipping = ManufacturingProcess.find_by(process_code: "P080")

equipments_data = [
  { equipment_code: "EQ-SLT-01", equipment_name: "슬리터 #1", manufacturing_process: slitting, location: "A동 1라인" },
  { equipment_code: "EQ-WND-01", equipment_name: "권선기 #1", manufacturing_process: winding, location: "A동 2라인" },
  { equipment_code: "EQ-WND-02", equipment_name: "권선기 #2", manufacturing_process: winding, location: "A동 2라인" },
  { equipment_code: "EQ-ASM-01", equipment_name: "조립기 #1", manufacturing_process: assembly, location: "B동 1라인" },
  { equipment_code: "EQ-MLD-01", equipment_name: "몰딩기 #1", manufacturing_process: molding, location: "B동 2라인" },
  { equipment_code: "EQ-MCH-01", equipment_name: "가공기 #1", manufacturing_process: machining, location: "C동 1라인" },
  { equipment_code: "EQ-INS-01", equipment_name: "검사기 #1", manufacturing_process: inspection, location: "C동 2라인" },
  { equipment_code: "EQ-PKG-01", equipment_name: "포장기 #1", manufacturing_process: packing, location: "D동 1라인" }
]
equipments_data.each do |data|
  Equipment.find_or_create_by!(equipment_code: data[:equipment_code]) do |equipment|
    equipment.assign_attributes(data)
  end
end

# 작업자 마스터
puts "[5/5] 작업자 마스터 생성 중..."
workers_data = [
  { employee_number: "GNT-001", name: "김철수", manufacturing_process: slitting },
  { employee_number: "GNT-002", name: "이영희", manufacturing_process: winding },
  { employee_number: "GNT-003", name: "박민수", manufacturing_process: winding },
  { employee_number: "GNT-004", name: "정수진", manufacturing_process: assembly },
  { employee_number: "GNT-005", name: "최동욱", manufacturing_process: molding },
  { employee_number: "GNT-006", name: "한지민", manufacturing_process: inspection },
  { employee_number: "GNT-007", name: "윤서영", manufacturing_process: packing },
  { employee_number: "GNT-008", name: "장현우", manufacturing_process: machining }
]
workers_data.each do |data|
  Worker.find_or_create_by!(employee_number: data[:employee_number]) do |worker|
    worker.assign_attributes(data)
  end
end

# 개발 환경 샘플 데이터 (작업지시 및 생산실적)
if Rails.env.development?
  puts "\n[개발 환경] 샘플 작업지시 및 생산실적 생성 중..."

  converter_product = Product.find_by(product_code: "CVT-001")
  transformer_product = Product.find_by(product_code: "TFI-001")

  # 작업지시 1: 컨버터 (진행중)
  wo1 = WorkOrder.find_or_create_by!(work_order_code: "WO-20260211-001") do |wo|
    wo.product = converter_product
    wo.order_qty = 500
    wo.plan_date = Date.current
    wo.priority = 8
    wo.status = :in_progress
  end

  # 작업지시 2: 트랜스포머 (계획)
  wo2 = WorkOrder.find_or_create_by!(work_order_code: "WO-20260211-002") do |wo|
    wo.product = transformer_product
    wo.order_qty = 1000
    wo.plan_date = Date.current + 1.day
    wo.priority = 5
    wo.status = :planned
  end

  # 생산실적 1: 권선 공정
  pr1 = ProductionResult.find_or_create_by!(lot_no: "L-20260211-CVT-001-001") do |pr|
    pr.work_order = wo1
    pr.manufacturing_process = winding
    pr.equipment = Equipment.find_by(equipment_code: "EQ-WND-01")
    pr.worker = Worker.find_by(employee_number: "GNT-002")
    pr.good_qty = 100
    pr.defect_qty = 5
    pr.start_time = Time.current - 2.hours
    pr.end_time = Time.current - 1.hour
  end

  # 불량 기록
  DefectRecord.find_or_create_by!(
    production_result: pr1,
    defect_code: DefectCode.find_by(code: "D04")
  ) do |dr|
    dr.defect_qty = 3
    dr.description = "코어 크랙 발생"
  end

  DefectRecord.find_or_create_by!(
    production_result: pr1,
    defect_code: DefectCode.find_by(code: "D09")
  ) do |dr|
    dr.defect_qty = 2
    dr.description = "외관 스크래치"
  end

  # 생산실적 2: 조립 공정
  ProductionResult.find_or_create_by!(lot_no: "L-20260211-CVT-001-002") do |pr|
    pr.work_order = wo1
    pr.manufacturing_process = assembly
    pr.equipment = Equipment.find_by(equipment_code: "EQ-ASM-01")
    pr.worker = Worker.find_by(employee_number: "GNT-004")
    pr.good_qty = 80
    pr.defect_qty = 0
    pr.start_time = Time.current - 1.hour
    pr.end_time = Time.current - 30.minutes
  end

  puts "  - 작업지시: #{WorkOrder.count}개"
  puts "  - 생산실적: #{ProductionResult.count}개"
  puts "  - 불량기록: #{DefectRecord.count}개"

  # ============================================================
  # 품질관리 샘플 데이터 (검사결과 + 검사항목)
  # ============================================================
  puts "\n[개발 환경] 검사결과 샘플 데이터 생성 중..."

  inspector = Worker.find_by(employee_number: "GNT-006") # 한지민 (검사 공정)
  insp_process = ManufacturingProcess.find_by(process_code: "P060") # 검사 공정

  inspection_spec = {
    "입력전압" => { spec: "DC 450~850V", unit: "V", base: 650.0, range: 40.0 },
    "출력전압" => { spec: "12.0 ± 0.5V", unit: "V", base: 12.0, range: 0.4 },
    "절연저항" => { spec: "≥ 100MΩ", unit: "MΩ", base: 350.0, range: 100.0 },
    "출력전류" => { spec: "0 ~ 250A", unit: "A", base: 125.0, range: 20.0 },
    "효율" => { spec: "≥ 93%", unit: "%", base: 95.0, range: 2.0 }
  }

  # 최근 30일간 검사결과 생성
  30.downto(0) do |days_ago|
    date = Date.current - days_ago.days
    # 하루에 2~4건 검사
    rand(2..4).times do |n|
      lot_no = "L-#{date.strftime('%Y%m%d')}-CVT-001-#{format('%03d', n + 1)}"
      insp_type = [ :incoming, :process, :outgoing ].sample

      ir = InspectionResult.find_or_create_by!(lot_no: lot_no, insp_type: insp_type, insp_date: date) do |r|
        r.worker = inspector
        r.manufacturing_process = insp_process
        r.result = rand(10) < 9 ? :pass : :fail # 90% 합격률
        r.notes = nil
      end

      # 검사항목 5개
      if ir.inspection_items.empty?
        inspection_spec.each do |name, spec|
          variation = (rand - 0.5) * 2 * spec[:range]
          measured = (spec[:base] + variation).round(2)
          fail_threshold = spec[:range] * 1.2

          InspectionItem.create!(
            inspection_result: ir,
            item_name: name,
            spec_value: spec[:spec],
            measured_value: measured,
            unit: spec[:unit],
            judgment: variation.abs > fail_threshold ? :fail : :pass
          )
        end
      end
    end
  end

  puts "  - 검사결과: #{InspectionResult.count}개"
  puts "  - 검사항목: #{InspectionItem.count}개"
end

puts "\n시드 데이터 생성 완료!"
puts "  - 사용자: #{User.count}명"
puts "  - 공정: #{ManufacturingProcess.count}개"
puts "  - 제품: #{Product.count}개"
puts "  - 불량코드: #{DefectCode.count}개"
puts "  - 설비: #{Equipment.count}대"
puts "  - 작업자: #{Worker.count}명"
