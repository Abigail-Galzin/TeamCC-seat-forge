class LogNotificationAdapter < NotificationAdapter
  def deliver(registration, event)
    Rails.logger.info(
      "[notification] registration=#{registration.id} attendee=#{registration.attendee_id} " \
      "session=#{registration.session_id} event=#{event}"
    )
  end
end
