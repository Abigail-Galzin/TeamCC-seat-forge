class AddStatusCheckToRegistrations < ActiveRecord::Migration[7.2]
  def change
    add_check_constraint :registrations, "status IN ('held', 'confirmed', 'waitlisted', 'cancelled', 'expired')", name: "registrations_status_check"
  end
end
