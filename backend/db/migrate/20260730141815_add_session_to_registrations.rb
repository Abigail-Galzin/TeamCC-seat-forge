class AddSessionToRegistrations < ActiveRecord::Migration[8.1]
  def change
    add_reference :registrations, :session, null: false, foreign_key: true
  end
end
