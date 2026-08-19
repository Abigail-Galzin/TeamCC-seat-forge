class User < ApplicationRecord
  has_secure_password

  belongs_to :attendee, optional: true
  has_many :auth_tokens, dependent: :destroy

  enum :role, {
    admin: "admin",
    attendee: "attendee"
  }, default: :attendee, validate: true

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
  validates :password, length: { minimum: 8 }, allow_nil: true

  def self.find_by_email(email)
    find_by("lower(email) = ?", email.to_s.strip.downcase)
  end
end