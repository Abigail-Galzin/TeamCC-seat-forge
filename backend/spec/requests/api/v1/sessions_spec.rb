require 'rails_helper'

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "GET /api/v1/sessions" do
    it "lists sessions ordered by starts_at ascending" do
      later = create(:session, starts_at: 3.days.from_now, ends_at: 3.days.from_now + 1.hour)
      sooner = create(:session, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)

      get "/api/v1/sessions"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |s| s["id"] }).to eq([ sooner.id, later.id ])
    end

    it "does not include seat availability fields" do
      create(:session)

      get "/api/v1/sessions"

      body = JSON.parse(response.body)
      expect(body["data"].first).not_to have_key("available_seats")
    end

    it "filters by status" do
      scheduled = create(:session, status: "scheduled")
      cancelled = create(:session, status: "cancelled")

      get "/api/v1/sessions", params: { status: "cancelled" }

      body = JSON.parse(response.body)
      expect(body["data"].map { |s| s["id"] }).to eq([ cancelled.id ])
    end

    it "filters by workshop_id" do
      workshop = create(:workshop)
      matching = create(:session, workshop: workshop)
      create(:session)

      get "/api/v1/sessions", params: { workshop_id: workshop.id }

      body = JSON.parse(response.body)
      expect(body["data"].map { |s| s["id"] }).to eq([ matching.id ])
    end

    it "filters by starts_after" do
      later = create(:session, starts_at: 5.days.from_now, ends_at: 5.days.from_now + 1.hour)
      sooner = create(:session, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)

      get "/api/v1/sessions", params: { starts_after: 3.days.from_now.iso8601 }

      body = JSON.parse(response.body)
      expect(body["data"].map { |s| s["id"] }).to eq([ later.id ])
    end

    it "filters by ends_before" do
      later = create(:session, starts_at: 5.days.from_now, ends_at: 5.days.from_now + 1.hour)
      sooner = create(:session, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)

      get "/api/v1/sessions", params: { ends_before: 3.days.from_now.iso8601 }

      body = JSON.parse(response.body)
      expect(body["data"].map { |s| s["id"] }).to eq([ sooner.id ])
    end

    it "paginates with the default page size" do
      13.times { |n| create(:session, starts_at: (n + 1).days.from_now, ends_at: (n + 1).days.from_now + 1.hour) }

      get "/api/v1/sessions"

      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(10)
      expect(body["pagination"]).to include("page" => 1, "count" => 13, "limit" => 10, "pages" => 2)
    end
  end

  describe "GET /api/v1/sessions/:id" do
    it "returns the session" do
      session = create(:session)

      get "/api/v1/sessions/#{session.id}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]).to include("id" => session.id, "capacity" => session.capacity)
    end

    it "does not include seat availability fields" do
      session = create(:session)

      get "/api/v1/sessions/#{session.id}"

      body = JSON.parse(response.body)
      expect(body["data"]).not_to have_key("available_seats")
    end

    it "returns a not_found error for an unknown session" do
      get "/api/v1/sessions/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/sessions/:id/availability" do
    it "returns seat availability details" do
      session = create(:session, capacity: 5)
      create(:registration, session: session, status: "held")
      create(:registration, session: session, status: "confirmed")
      create(:registration, session: session, status: "waitlisted")

      get "/api/v1/sessions/#{session.id}/availability"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]).to include(
        "id" => session.id,
        "held_seats" => 1,
        "confirmed_seats" => 1,
        "waitlist_size" => 1,
        "capacity" => 5
      )
    end

    it "returns a not_found error for an unknown session" do
      get "/api/v1/sessions/999999/availability"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/workshops/:workshop_id/sessions" do
    it "creates a session for an active workshop" do
      workshop = create(:workshop, active: true)

      post "/api/v1/workshops/#{workshop.id}/sessions", params: {
        session: { starts_at: 1.day.from_now.iso8601, ends_at: (1.day.from_now + 1.hour).iso8601, capacity: 10 }
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["capacity"]).to eq(10)
    end

    it "rejects creating a session for an inactive workshop" do
      workshop = create(:workshop, active: false)

      post "/api/v1/workshops/#{workshop.id}/sessions", params: {
        session: { starts_at: 1.day.from_now.iso8601, ends_at: (1.day.from_now + 1.hour).iso8601, capacity: 10 }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Cannot create session for inactive workshop")
    end

    it "returns a conflict error when session validation fails" do
      workshop = create(:workshop, active: true)

      post "/api/v1/workshops/#{workshop.id}/sessions", params: {
        session: { starts_at: 1.day.from_now.iso8601, ends_at: (1.day.from_now + 1.hour).iso8601, capacity: -1 }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("creation_conflict")
    end

    it "returns a not_found error for an unknown workshop" do
      post "/api/v1/workshops/999999/sessions", params: {
        session: { starts_at: 1.day.from_now.iso8601, ends_at: (1.day.from_now + 1.hour).iso8601, capacity: 10 }
      }

      expect(response).to have_http_status(:not_found)
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
