class Workshop < ApplicationRecord
  has_many :sessions, dependent: :destroy

  validates :title, presence: true
  validates :topic, presence: true
  validates :active, inclusion: { in: [true, false] }
end
