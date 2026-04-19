class SensorChannel < ApplicationCable::Channel
  def subscribed
    if params[:node_code].present?
      stream_from "sensor_#{params[:node_code]}"
    else
      stream_from "sensor_all"
    end
  end
end
