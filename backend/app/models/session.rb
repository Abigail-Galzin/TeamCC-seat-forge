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

  private

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
end
