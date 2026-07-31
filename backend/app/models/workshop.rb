class Workshop < ApplicationRecord
  has_many :sessions, dependent: :destroy

  def current_or_next_session
    now = Time.current

    sessions.scheduled.where("starts_at <= ? AND ends_at >= ?", now, now).first ||
      sessions.scheduled.where("starts_at > ?", now).order(:starts_at).first
  end

  validates :title, presence: true, length: { minimum: 3, maximum: 150 }
  validates :topic, presence: true, length: { minimum: 2, maximum: 100 }
  validates :active, inclusion: { in: [true, false] }

  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :title, format: {
    with: /\A[a-zA-Z0-9\s\-_.,áéíóúÁÉÍÓÚñÑ]+\z/,
    message: I18n.t('errors.invalid_characters'),
  }, allow_blank: true

  validates :title, format: {
    without: /\A\d+\z/,
    message: I18n.t('errors.invalid_characters'),
  }, allow_blank: true

  validates :description, format: {
    without: /\A\d+\z/,
    message: I18n.t('errors.invalid_characters'),
  }, allow_blank: true
end
