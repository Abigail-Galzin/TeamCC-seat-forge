FactoryBot.define do
  factory :user do
    name { "Jane Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { "attendee" }

    trait :admin do
      role { "admin" }
    end
  end
end