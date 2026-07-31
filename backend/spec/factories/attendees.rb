FactoryBot.define do
  factory :attendee do
    name { "MyString" }
    sequence(:email) { |n| "attendee#{n}@example.com" }
  end
end
