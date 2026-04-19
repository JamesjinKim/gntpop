module Api
  module V1
    class SensorReadingsController < BaseController
      def create
        # Layer 1 구현 시 실제 로직 추가
        render json: { status: "ok", message: "Sensor readings endpoint ready" }, status: :created
      end
    end
  end
end
