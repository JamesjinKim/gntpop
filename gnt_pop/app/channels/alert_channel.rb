class AlertChannel < ApplicationCable::Channel
  def subscribed
    stream_from "alerts_all"
    stream_from "alerts_safety"
    stream_from "alerts_quality"
  end
end
