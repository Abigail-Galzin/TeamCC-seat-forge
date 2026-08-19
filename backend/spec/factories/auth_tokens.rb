FactoryBot.define do
  factory :auth_token do
    user

    token_digest { Digest::SHA256.hexdigest(SecureRandom.base58(32)) }
    expires_at { 24.hours.from_now }
  end
end