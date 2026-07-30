FactoryBot.define do
  factory :session do
    starts_at { "2026-07-30 09:37:54" }
    ends_at { "2026-07-30 09:37:54" }
    capacity { 1 }
    status { "MyString" }
  end
end
