class ChangeDefaultStatusOnRegistrations < ActiveRecord::Migration[7.2]
  def change
    change_column_default :registrations, :status, from: "available", to: "held"
  end
end
