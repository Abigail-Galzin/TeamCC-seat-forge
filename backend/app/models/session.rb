class Session < ApplicationRecord
  belongs_to :workshop
  has_many :registrations, dependent: :destroy

  enum :status, {
    scheduled:"scheduled",
    cancelled:"cancelled",
    completed:"completed",
  }, validate: true

  validates :workshop, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :starts_at, presence: true
  validates :ends_at, presence: true

  validate :starts_at_and_ends_at_are_valid_iso8601
  validate :starts_at_must_be_earlier_than_ends_at
  validate :starts_in_future, on: :create

  def held_seats
    registrations.where(status: :held).count
  end

  def confirmed_seats
    registrations.where(status: :confirmed).count
  end

  def waitlist_size
    registrations.where(status: :waitlisted).count
  end

  def available_seats
    [capacity - confirmed_seats, 0].max
  end

  def in_progress?
    now = Time.current
    starts_at <= now && ends_at >= now
  end

  NOTIFIABLE_REGISTRATION_STATUSES = %w[held confirmed].freeze

  # Idempotent: cancelling an already-cancelled session is a no-op that
  # still returns true with zero counts, instead of re-cancelling
  # registrations or re-enqueueing notifications. Locks the session first,
  # then locks and updates only the held/confirmed/waitlisted registrations
  # in the same transaction — expired/cancelled registrations are excluded
  # from the query entirely so they're never touched. Mirrors the lock
  # order and idempotency guard used by Registration#cancel.
  def cancel(reason)
    return [true, cancelled_counts_zero] if cancelled?

    # The transaction's own return value becomes `counts` — no pre-declared
    # mutable locals needed. Each branch ends with the counts it wants
    # reported, so whichever one runs is what falls out of the block.
    counts = transaction do
      locked_session = self.class.lock.find(id)

      next cancelled_counts_zero if locked_session.cancelled?

      targets = locked_session.registrations
        .where(status: Registration::ACTIVE_STATUSES)
        .lock
        .to_a

      registration_counts = cancelled_counts_zero.merge(targets.group_by(&:status).transform_values(&:count))
      notify_ids = targets.select { |r| NOTIFIABLE_REGISTRATION_STATUSES.include?(r.status) }.map(&:id)

      targets.each { |r| r.update!(status: "cancelled", cancelled_at: Time.current, hold_expires_at: nil) }

      locked_session.update!(status: "cancelled", cancellation_reason: reason, cancelled_at: Time.current)
      reload

      notify_ids.each { |id| RegistrationNotificationJob.perform_later(id, "session_cancelled") }

      registration_counts
    end

    [true, counts]
  end

  private

  def cancelled_counts_zero
    { "held" => 0, "confirmed" => 0, "waitlisted" => 0 }
  end

  def starts_at_and_ends_at_are_valid_iso8601
    validate_iso8601_format(:starts_at, starts_at_before_type_cast)
    validate_iso8601_format(:ends_at, ends_at_before_type_cast)
  end

  def validate_iso8601_format(attribute, raw_value)
    return if raw_value.blank?

    return if raw_value.is_a?(Time) || raw_value.is_a?(DateTime) || raw_value.is_a?(ActiveSupport::TimeWithZone)

    Time.iso8601(raw_value.to_s)
  rescue ArgumentError
    errors.add(attribute, "must be a valid ISO 8601 timestamp")
  end

  def starts_at_must_be_earlier_than_ends_at
    return if starts_at.blank? || ends_at.blank?

    if starts_at >= ends_at
      errors.add(:starts_at, "must be earlier than ends_at")
    end
  end

  def starts_in_future
    return if starts_at.blank? || !starts_at.is_a?(Time)

    if starts_at <= Time.current
      errors.add(:starts_at, "must be in the future")
    end
  end
end
