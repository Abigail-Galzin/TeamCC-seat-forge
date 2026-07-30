class CreateRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :registrations do |t|
      t.string :status, null: false, default: "available"
      t.datetime :hold_expires_at
      t.datetime :confirmed_at
      t.datetime :cancelled_at
      t.references :attendee, null: false, foreign_key: true

      t.timestamps
    end      

  end
end
