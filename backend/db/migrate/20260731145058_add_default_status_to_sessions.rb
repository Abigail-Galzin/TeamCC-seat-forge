class AddDefaultStatusToSessions < ActiveRecord::Migration[7.2]
  def change
    change_column_default :sessions, :status, from: nil, to: "scheduled"
    change_column_null :sessions, :status, false, "scheduled"
  end
end
