class CleanupJob < ApplicationJob
  queue_as :default

  HOLD_DURATION = 10.minutes

  def perform
    expired_holds.find_each do |registration|
      registration.transaction do
        registration.update!(status: :expired)
        promote_next_waitlisted
      end
    end
  end

  private

  def expired_holds
    Registration.where(status: :held).where("hold_expires_at < ?", Time.current)
  end

  # TODO: scope by session_id once that column exists; for now treats all
  # waitlisted registrations as one shared waitlist.
  def promote_next_waitlisted
    next_registration = Registration
      .where(status: :waitlisted)
      .order(created_at: :asc)
      .lock
      .first

    return unless next_registration

    next_registration.update!(status: :held, hold_expires_at: Time.current + HOLD_DURATION)
    notify(next_registration)
  end

  def notify(registration)
    attendee = registration.attendee

    Rails.logger.info(
      "[Notification] To: #{attendee.name} <#{attendee.email}> - " \
      "Please confirm your registration before #{registration.hold_expires_at}"
    )
  end
end
