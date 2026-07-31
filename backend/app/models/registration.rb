class Registration < ApplicationRecord
  ACTIVE_STATUSES = %w[held confirmed waitlisted].freeze
  HOLD_DURATION = 10.minutes
  DUPLICATE_ACTIVE_REGISTRATION_MESSAGE = "attendee already has an active registration for this session".freeze

  belongs_to :attendee
  belongs_to :session

  enum :status, {
      held:"held",
      confirmed:"confirmed",
      waitlisted:"waitlisted",
      cancelled:"cancelled",
      expired:"expired"
  }, validate: true

  validates :status, presence: true

  validate :session_must_be_open_for_registration, on: :create
  validate :attendee_must_not_have_duplicate_active_registration, on: :create
  validate :attendee_must_not_have_overlapping_registration, on: :create

  scope :by_status,      ->(status)   { where(status: status) }
  
  def self.register(attendee:, session:)
    registration = new(attendee: attendee, session: session)

    transaction do
      locked_session = Session.lock.find(session.id)
      registration.session = locked_session

      raise ActiveRecord::Rollback unless registration.valid?

      seats_taken = locked_session.registrations.where(status: %w[held confirmed]).count

      if seats_taken < locked_session.capacity
        registration.status = "held"
        registration.hold_expires_at = HOLD_DURATION.from_now
      else
        registration.status = "waitlisted"
      end

      registration.save
    end

    registration
  end

  # Finds held registrations whose hold has lapsed and expires each one.
  # Safe to run more than once, concurrently, or interleaved with a manual
  # confirm/cancel: #expire_hold re-checks under a row lock before acting.
  def self.expire_overdue_holds
    where(status: "held").where("hold_expires_at <= ?", Time.current).find_each(&:expire_hold)
  end

  # Promotes the oldest waitlisted registration for locked_session to held
  # and notifies it. locked_session must already be locked (SELECT ...
  # FOR UPDATE) by the caller so this can't race a concurrent release of
  # the same seat. Used by every path that frees a held/confirmed seat
  # (cancellation, expiration) so promotion is one consistent workflow.
  def self.promote_oldest_waitlisted(locked_session)
    next_in_line = locked_session.registrations
      .where(status: "waitlisted")
      .order(:created_at)
      .lock
      .first

    return if next_in_line.blank?

    next_in_line.update!(status: "held", hold_expires_at: HOLD_DURATION.from_now)
    RegistrationNotificationJob.perform_later(next_in_line.id, "waitlist_promoted")
  end

  def expired?
    hold_expires_at.present? && hold_expires_at < Time.current
  end

  # Idempotent: confirming an already-confirmed registration is a no-op
  # that still returns true, instead of re-running confirmation effects.
  # Re-checks eligibility under a row lock (lock!) so two concurrent
  # confirm calls on the same registration can't both enqueue a
  # notification.
  def confirm
    return true if confirmed?

    result = transaction do
      lock!

      if confirmed?
        :already_confirmed
      elsif held? && !expired?
        update!(status: "confirmed", confirmed_at: Time.current, hold_expires_at: nil)
        :confirmed
      else
        errors.add(:base, "only a non-expired held registration can be confirmed")
        raise ActiveRecord::Rollback
      end
    end

    RegistrationNotificationJob.perform_later(id, "confirmed") if result == :confirmed
    result.present?
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Idempotent: cancelling an already-cancelled registration is a no-op
  # that still returns true. Releasing a held/confirmed seat promotes the
  # oldest waitlisted registration for the same session to held. Locks the
  # session first, then this registration (lock!) — the same lock order
  # used by #register/#expire_hold — so a concurrent cancel of the same
  # registration can't double-release the seat or double-promote.
  def cancel
    return true if cancelled?

    result = transaction do
      locked_session = Session.lock.find(session_id)
      lock!

      if cancelled?
        :already_cancelled
      elsif held? || confirmed? || waitlisted?
        seat_released = held? || confirmed?

        update!(status: "cancelled", cancelled_at: Time.current, hold_expires_at: nil)
        self.class.promote_oldest_waitlisted(locked_session) if seat_released

        :cancelled
      else
        errors.add(:base, "only a held, confirmed, or waitlisted registration can be cancelled")
        raise ActiveRecord::Rollback
      end
    end

    result.present?
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Idempotent: re-checks under lock that this registration is still held
  # and still overdue before acting, so a duplicate/overlapping run (or a
  # run that races a manual confirm/cancel) is a safe no-op.
  def expire_hold
    return true unless held?

    transaction do
      locked_session = Session.lock.find(session_id)
      locked = locked_session.registrations.lock.find(id)

      unless locked.held? && locked.hold_expires_at.present? && locked.hold_expires_at <= Time.current
        next
      end

      locked.update!(status: "expired")
      self.class.promote_oldest_waitlisted(locked_session)
    end

    true
  end

  private

  def session_must_be_open_for_registration
    return if session.blank?

    if session.cancelled? || session.completed?
      errors.add(:session, "is not open for registration")
    elsif session.starts_at.present? && session.starts_at <= Time.current
      errors.add(:session, "has already started")
    end
  end

  def attendee_must_not_have_duplicate_active_registration
    return if attendee.blank? || session.blank?

    duplicates = Registration.where(attendee_id: attendee_id, session_id: session_id, status: ACTIVE_STATUSES)
    duplicates = duplicates.where.not(id: id) if persisted?

    errors.add(:base, DUPLICATE_ACTIVE_REGISTRATION_MESSAGE) if duplicates.exists?
  end

  def attendee_must_not_have_overlapping_registration
    return if attendee.blank? || session.blank?
    return if session.starts_at.blank? || session.ends_at.blank?

    overlapping = attendee.registrations
      .where(status: %w[held confirmed])
      .where.not(session_id: session_id)
      .joins(:session)
      .where("sessions.starts_at < ? AND sessions.ends_at > ?", session.ends_at, session.starts_at)

    overlapping = overlapping.where.not(id: id) if persisted?

    errors.add(:base, "attendee has an overlapping registration for this time") if overlapping.exists?
  end
end
