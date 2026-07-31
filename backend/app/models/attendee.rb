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

  def self.find_by_email(email)
    find_by("lower(email) = ?", email.to_s.strip.downcase)
  end

end
