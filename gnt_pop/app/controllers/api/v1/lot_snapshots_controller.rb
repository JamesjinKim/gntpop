module Api
  module V1
    class LotSnapshotsController < BaseController
      def create
        production_result = ProductionResult.find(params[:production_result_id])
        snapshot = LotSensorSnapshotService.capture!(
          production_result,
          snapshot_type: params[:snapshot_type] || "start"
        )
        render json: snapshot, status: :created
      end

      def index
        snapshots = LotSensorSnapshot.by_lot(params[:lot_no])
        render json: { lot_no: params[:lot_no], snapshots: snapshots }
      end
    end
  end
end
