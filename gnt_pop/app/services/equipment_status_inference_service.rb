# frozen_string_literal: true

# 센서 데이터 기반 설비 상태 추론 서비스
# IoT 센서 데이터를 입력받아 설비 상태(idle/run/down)를 판단
#
# 사용 예시:
#   status = EquipmentStatusInferenceService.infer(vibration_rms: 1.5, temperature: 45.0)
#   # => :run
class EquipmentStatusInferenceService
  def self.infer(sensor_data)
    vibration = sensor_data[:vibration_rms] || sensor_data["vibration_rms"]
    temperature = sensor_data[:temperature] || sensor_data["temperature"]

    if vibration.present? && (vibration > 2.0 || (temperature.present? && temperature > 80.0))
      :down
    elsif vibration.present? && vibration > 0.3
      :run
    else
      :idle
    end
  end
end
