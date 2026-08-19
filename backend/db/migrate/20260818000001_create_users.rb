class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, default: "attendee", null: false
      t.references :attendee, foreign_key: true, null: true

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_check_constraint :users, "role::text = ANY (ARRAY['admin'::character varying::text, 'attendee'::character varying::text])", name: "users_role_check"
  end
end