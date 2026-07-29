FactoryBot.define do
  factory :registration do
    status { "MyString" }
    hold_expires_at { "2026-07-29 17:02:47" }
    confirmed_at { "2026-07-29 17:02:47" }
    cancelled_at { "2026-07-29 17:02:47" }
    Attendee { nil }
  end
end
