module PaymentsHelper
  # Server-rendered "mm:ss" so the timer reads right before the countdown controller takes over.
  def time_left(expires_at)
    Time.at([ expires_at - Time.current, 0 ].max).utc.strftime("%M:%S")
  end
end
