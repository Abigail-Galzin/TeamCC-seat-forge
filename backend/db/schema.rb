# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_07_31_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attendees", force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["email"], name: "index_attendees_on_email", unique: true
  end

  create_table "registrations", force: :cascade do |t|
    t.bigint "attendee_id", null: false
    t.datetime "cancelled_at"
    t.datetime "confirmed_at"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "hold_expires_at"
    t.string "status", default: "held", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "session_id", null: false
    t.index ["attendee_id"], name: "index_registrations_on_attendee_id"
    t.index ["session_id"], name: "index_registrations_on_session_id"
    t.check_constraint "status::text = ANY (ARRAY['held'::character varying::text, 'confirmed'::character varying::text, 'waitlisted'::character varying::text, 'cancelled'::character varying::text, 'expired'::character varying::text])", name: "registrations_status_check"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "capacity", null: false
    t.string "status", default: "scheduled", null: false
    t.bigint "workshop_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "cancellation_reason"
    t.datetime "cancelled_at"
    t.index ["workshop_id"], name: "index_sessions_on_workshop_id"
    t.check_constraint "capacity > 0", name: "sessions_capacity_check"
    t.check_constraint "starts_at < ends_at", name: "sessions_dates_check"
    t.check_constraint "status::text = ANY (ARRAY['scheduled'::character varying::text, 'cancelled'::character varying::text, 'completed'::character varying::text])", name: "sessions_status_check"
  end

  create_table "workshops", force: :cascade do |t|
    t.string "title", null: false
    t.string "description"
    t.string "topic", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  add_foreign_key "registrations", "attendees"
  add_foreign_key "registrations", "sessions"
  add_foreign_key "sessions", "workshops"
end
