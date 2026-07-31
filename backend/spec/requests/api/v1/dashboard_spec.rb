require 'rails_helper'

RSpec.describe "Api::V1::Dashboard", type: :request do
  describe "GET /api/v1/dashboard" do
    it "lists only active workshops, ordered by title" do
      create(:workshop, title: "Zeta Workshop", active: true)
      create(:workshop, title: "Alpha Workshop", active: true)
      create(:workshop, title: "Inactive Workshop", active: false)

      get "/api/v1/dashboard"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |w| w["title"] }).to eq([ "Alpha Workshop", "Zeta Workshop" ])
    end

    it "includes the current or next session summary for each workshop" do
      workshop = create(:workshop, active: true)
      session = create(:session, workshop: workshop, capacity: 5,
        starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
      create(:registration, session: session, status: "confirmed")

      get "/api/v1/dashboard"

      body = JSON.parse(response.body)
      current_session = body["data"].first["current_session"]
      expect(current_session).to include("id" => session.id, "available_seats" => 4)
    end

    it "returns a nil current_session when the workshop has no upcoming or in-progress sessions" do
      create(:workshop, active: true)

      get "/api/v1/dashboard"

      body = JSON.parse(response.body)
      expect(body["data"].first["current_session"]).to be_nil
    end
  end

  describe "GET /api/v1/workshops/:workshop_id/dashboard" do
    it "returns aggregated metrics for the workshop" do
      workshop = create(:workshop)
      full_session = create(:session, workshop: workshop, capacity: 1,
        starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
      create(:registration, session: full_session, status: "confirmed")

      open_session = create(:session, workshop: workshop, capacity: 5,
        starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour)
      create(:registration, session: open_session, status: "held")
      create(:registration, session: open_session, status: "waitlisted")
      create(:registration, session: open_session, status: "expired", hold_expires_at: nil)

      get "/api/v1/workshops/#{workshop.id}/dashboard"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]).to include(
        "workshop_id" => workshop.id,
        "workshop_title" => workshop.title,
        "upcoming_sessions" => 2,
        "held_registrations" => 1,
        "confirmed_registrations" => 1,
        "waitlisted_registrations" => 1,
        "expired_holds_today" => 1,
        "full_sessions" => 1
      )
      expect(body["data"]["top_waitlisted_sessions"]).to eq(
        [ { "session_id" => open_session.id, "starts_at" => open_session.starts_at.iso8601, "waitlist_size" => 1 } ]
      )
    end

    it "does not include another workshop's sessions in the metrics" do
      workshop = create(:workshop)
      other_workshop = create(:workshop)
      create(:session, workshop: other_workshop, capacity: 5,
        starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)

      get "/api/v1/workshops/#{workshop.id}/dashboard"

      body = JSON.parse(response.body)
      expect(body["data"]["upcoming_sessions"]).to eq(0)
    end

    it "returns a not_found error for an unknown workshop" do
      get "/api/v1/workshops/999999/dashboard"

      expect(response).to have_http_status(:not_found)
    end
  end
end
