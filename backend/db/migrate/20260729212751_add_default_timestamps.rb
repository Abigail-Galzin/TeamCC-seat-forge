class AddDefaultTimestamps < ActiveRecord::Migration[7.2]
  def change
    change_column_default :attendees, :created_at, -> { "CURRENT_TIMESTAMP" }
    change_column_default :attendees, :updated_at, -> { "CURRENT_TIMESTAMP" }

    change_column_default :registrations, :created_at, -> { "CURRENT_TIMESTAMP" }
    change_column_default :registrations, :updated_at, -> { "CURRENT_TIMESTAMP" }
  end
end
