class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.datetime :starts_at, null:false
      t.datetime :ends_at, null:false
      t.integer :capacity, null:false
      t.string :status, null:false

      t.references :workshop, null: false, foreign_key: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_check_constraint :sessions, "capacity > 0", name: "sessions_capacity_check"
    add_check_constraint :sessions, "starts_at < ends_at", name: "sessions_dates_check"
    add_check_constraint :sessions, "status IN ('scheduled', 'cancelled', 'completed')", name: 'sessions_status_check'
  end
end
