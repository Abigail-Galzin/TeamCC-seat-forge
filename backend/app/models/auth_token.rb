class AuthToken < ApplicationRecord
  TOKEN_LENGTH = 32
  DEFAULT_TTL = 24.hours
  TOKEN_ALGORITHM = "SHA256".freeze

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # Issues a new opaque bearer token for a user. Returns the plaintext token
  # exactly once; only its SHA-256 digest is persisted so a DB leak never
  # exposes usable credentials.
  def self.issue_for(user, expires_at: DEFAULT_TTL.from_now)
    token = SecureRandom.base58(TOKEN_LENGTH)
    create!(
      user: user,
      token_digest: digest_for(token),
      expires_at: expires_at
    )
    token
  end

  # Returns the AuthToken record for a live, non-revoked, non-expired
  # plaintext token, or nil.
  def self.authenticate(token)
    return nil if token.blank?

    record = find_by(token_digest: digest_for(token), revoked_at: nil)
    return nil if record.nil? || record.expired?

    record
  end

  def self.digest_for(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked_at.present?
  end
end