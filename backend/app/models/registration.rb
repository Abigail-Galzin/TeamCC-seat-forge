class Registration < ApplicationRecord
  belongs_to :Attendee


  enum :status, {
      available:"available",
      held:"held",
      confirmed:"confirmed",
      waitlisted:"waitlisted",
      cancelled:"cancelled",
      expired:"expired"
  }, validate: true

  validates :status, presence: true

   
  scope :by_status,      ->(status)   { where(status: status) }


  def expired?
    hold_expires_at.present? && hold_expires_at < Time.current
  end


end
