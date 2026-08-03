require 'rails_helper'

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "GET /index" do
    it "filters by workshop_id" do
      workshop_a = create(:workshop)
      workshop_b = create(:workshop)
      session_a = create(:session, workshop: workshop_a)
      create(:session, workshop: workshop_b)

      get "/api/v1/sessions", params: { workshop_id: workshop_a.id }

      json = response.parsed_body
      expect(json["data"].map { |s| s["id"] }).to eq([ session_a.id ])
    end

    it "filters by topic, case-insensitively" do
      rails_workshop = create(:workshop, topic: "Rails")
      vue_workshop = create(:workshop, topic: "Vue")
      rails_session = create(:session, workshop: rails_workshop)
      create(:session, workshop: vue_workshop)

      get "/api/v1/sessions", params: { topic: "rails" }

      json = response.parsed_body
      expect(json["data"].map { |s| s["id"] }).to eq([ rails_session.id ])
      expect(json["data"].first["topic"]).to eq("Rails")
    end

    it "filters by available=true, excluding full sessions" do
      full_session = create(:session, capacity: 1)
      open_session = create(:session, capacity: 1)
      create(:registration, session: full_session, status: "confirmed")

      get "/api/v1/sessions", params: { available: true }

      json = response.parsed_body
      ids = json["data"].map { |s| s["id"] }
      expect(ids).to include(open_session.id)
      expect(ids).not_to include(full_session.id)
    end

    it "sorts by available_seats ascending when requested" do
      roomy = create(:session, capacity: 5)
      tight = create(:session, capacity: 1)
      create(:registration, session: tight, status: "confirmed")

      get "/api/v1/sessions", params: { sort: "available_seats" }

      json = response.parsed_body
      ids = json["data"].map { |s| s["id"] }
      expect(ids.index(tight.id)).to be < ids.index(roomy.id)
    end

    it "includes availability counts and topic in each record" do
      session = create(:session, capacity: 3)
      create(:registration, session: session, status: "confirmed")
      create(:registration, session: session, status: "held")

      get "/api/v1/sessions"

      json = response.parsed_body
      record = json["data"].find { |s| s["id"] == session.id }
      expect(record).to include(
        "topic" => session.workshop.topic,
        "confirmed_seats" => 1,
        "held_seats" => 1,
        "available_seats" => 2
      )
    end

    it "includes a null cancellation_reason for a scheduled session and the real reason for a cancelled one" do
      scheduled = create(:session)
      cancelled = create(:session)
      cancelled.cancel("Instructor unavailable")

      get "/api/v1/sessions"

      json = response.parsed_body
      scheduled_record = json["data"].find { |s| s["id"] == scheduled.id }
      cancelled_record = json["data"].find { |s| s["id"] == cancelled.id }
      expect(scheduled_record["cancellation_reason"]).to be_nil
      expect(cancelled_record["cancellation_reason"]).to eq("Instructor unavailable")
    end

    it "paginates using per_page" do
      create_list(:session, 3)

      get "/api/v1/sessions", params: { per_page: 1, page: 2 }

      json = response.parsed_body
      expect(json["data"].length).to eq(1)
      expect(json["pagination"]).to include("page" => 2, "pages" => 3, "limit" => 1)
    end
  end

  describe "GET /show" do
    it "returns the session" do
      session = create(:session)

      get "/api/v1/sessions/#{session.id}"

      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json["data"]["id"]).to eq(session.id)
    end

    it "includes the cancellation reason for a cancelled session" do
      session = create(:session)
      session.cancel("Instructor unavailable")

      get "/api/v1/sessions/#{session.id}"

      json = response.parsed_body
      expect(json["data"]["cancellation_reason"]).to eq("Instructor unavailable")
    end
  end

  describe "POST /create" do
    it "creates a session under the workshop with the given status" do
      workshop = create(:workshop, active: true)

      post "/api/v1/workshops/#{workshop.id}/sessions", params: {
        session: { starts_at: 2.days.from_now.iso8601, ends_at: 2.days.from_now.advance(hours: 2).iso8601, capacity: 5, status: "cancelled" }
      }

      json = response.parsed_body
      expect(response).to have_http_status(:created)
      expect(json["data"]["status"]).to eq("cancelled")
    end
  end

  describe "POST /api/v1/sessions/:id/cancel" do
    it "cancels the session and its held, confirmed, and waitlisted registrations" do
      session = create(:session, capacity: 5)
      create(:registration, session: session, status: "held")
      create(:registration, session: session, status: "held")
      create(:registration, session: session, status: "confirmed", confirmed_at: 1.hour.ago, hold_expires_at: nil)
      create(:registration, session: session, status: "waitlisted", hold_expires_at: nil)

      post "/api/v1/sessions/#{session.id}/cancel", params: { cancellation_reason: "Instructor unavailable" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]).to eq(
        "session_id" => session.id,
        "status" => "cancelled",
        "cancellation_reason" => "Instructor unavailable",
        "cancelled_registrations" => { "held" => 2, "confirmed" => 1, "waitlisted" => 1 }
      )
    end

    it "rejects a blank cancellation reason" do
      session = create(:session)

      post "/api/v1/sessions/#{session.id}/cancel", params: { cancellation_reason: "  " }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(session.reload.status).to eq("scheduled")
    end

    it "rejects a missing cancellation reason" do
      session = create(:session)

      post "/api/v1/sessions/#{session.id}/cancel"

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "is idempotent when the session is already cancelled" do
      session = create(:session, capacity: 5)
      create(:registration, session: session, status: "held")

      post "/api/v1/sessions/#{session.id}/cancel", params: { cancellation_reason: "First reason" }
      post "/api/v1/sessions/#{session.id}/cancel", params: { cancellation_reason: "Second reason" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["cancellation_reason"]).to eq("First reason")
      expect(body["data"]["cancelled_registrations"]).to eq("held" => 0, "confirmed" => 0, "waitlisted" => 0)
    end

    it "returns a not_found error for an unknown session" do
      post "/api/v1/sessions/999999/cancel", params: { cancellation_reason: "Instructor unavailable" }

      expect(response).to have_http_status(:not_found)
    end

    it "rejects new registrations against the cancelled session with a conflict response" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      post "/api/v1/sessions/#{session.id}/cancel", params: { cancellation_reason: "Instructor unavailable" }

      attendee = create(:attendee)
      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", params: {
        attendee: { name: attendee.name, email: attendee.email }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("creation_conflict")
    end
  end
end
