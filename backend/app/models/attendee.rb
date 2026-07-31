class Attendee < ApplicationRecord
  has_many :registrations, dependent: :destroy


  validates :name, presence: true,
          format: {
            with: /\A[\p{L}\s]+\z/,
            message: "can only contain letters and spaces"
          }
  validates :email, presence: true, uniqueness: { case_sensitive: false },
  format: {
    with: URI::MailTo::EMAIL_REGEXP,
    message: "must be a valid email address"
  }

  def registration_status_counts
    Registration.statuses.keys.index_with(0).merge(registrations.group(:status).count)
  end

  # Finds the attendee by email (case-insensitive), or builds and attempts to
  # save a new one. Returns the attendee either way; check #persisted? to
  # tell an existing/newly-saved attendee apart from one that failed to save.
  def self.find_or_create_for_registration(name:, email:)
    normalized_email = email.to_s.strip

    find_by("lower(email) = ?", normalized_email.downcase) ||
      new(name: name.to_s.strip, email: normalized_email).tap(&:save)
  end

end
