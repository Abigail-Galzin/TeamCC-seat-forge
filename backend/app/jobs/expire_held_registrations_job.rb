# Scheduled via config/recurring.yml (Solid Queue). Safe to run more than
# once, concurrently, or overlap with a manual confirm/cancel: see
# Registration.expire_overdue_holds / #expire_hold for the locking that
# makes this idempotent.
class ExpireHeldRegistrationsJob < ApplicationJob
  queue_as :background

  def perform
    Registration.expire_overdue_holds
  end
end
