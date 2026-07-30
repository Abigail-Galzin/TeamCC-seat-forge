class RegistrationNotificationJob < ApplicationJob
  queue_as :default

  def perform(registration_id, event)
    registration = Registration.find_by(id: registration_id)
    return if registration.nil?

    NotificationAdapter.current.deliver(registration, event)
  end
end
