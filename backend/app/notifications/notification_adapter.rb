# Swappable notification strategy. Callers never talk to a concrete
# delivery mechanism directly, only to NotificationAdapter.current, so the
# adapter can be replaced (tests, a real mailer/SMS provider, etc.) without
# touching Registration or the jobs that enqueue notifications.
class NotificationAdapter
  class << self
    def current
      @current ||= LogNotificationAdapter.new
    end

    attr_writer :current
  end

  def deliver(registration, event)
    raise NotImplementedError, "#{self.class} must implement #deliver"
  end
end
