FactoryBot.define do
  factory :session do
    workshop
    starts_at { 1.day.from_now }
    ends_at { 1.day.from_now + 2.hours }
    capacity { 10 }
    status { "scheduled" }
  end
end
