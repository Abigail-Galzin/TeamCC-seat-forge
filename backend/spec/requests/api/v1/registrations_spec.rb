require 'rails_helper'

RSpec.describe "Api::V1::Registrations", type: :request do
  describe "GET /api/v1/workshops/:workshop_id/sessions/:session_id/registrations" do
    it "lists the attendees registered for the session, most recent first, with attendee details" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 10)
      attendee = create(:attendee, name: "Jane Doe", email: "jane@example.com")
      older = create(:registration, attendee: attendee, session: session, status: "confirmed", created_at: 2.days.ago)
      newer = create(:registration, session: session, status: "held", created_at: 1.hour.ago)

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |r| r["id"] }).to eq([ newer.id, older.id ])
      expect(body["data"].last["attendee"]).to eq({ "id" => attendee.id, "name" => "Jane Doe", "email" => "jane@example.com" })
    end

    it "only includes registrations for the given session" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 10)
      other_session = create(:session, workshop: workshop, capacity: 10)
      create(:registration, session: session)
      create(:registration, session: other_session)

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations"

      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(1)
    end

    it "paginates with the default page size" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 30)
      12.times { create(:registration, session: session) }

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations"

      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(10)
      expect(body["pagination"]).to include("page" => 1, "count" => 12, "limit" => 10, "pages" => 2)
    end

    it "respects a valid per_page param, capped at the app-wide Pagy default" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 60)
      15.times { create(:registration, session: session) }

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", params: { per_page: 5 }
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(5)
      expect(body["pagination"]["limit"]).to eq(5)

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", params: { per_page: 1000 }
      body = JSON.parse(response.body)
      expect(body["pagination"]["limit"]).to eq(Pagy::DEFAULT[:items])
    end

    it "returns a not_found error for an unknown session" do
      workshop = create(:workshop)

      get "/api/v1/workshops/#{workshop.id}/sessions/999999/registrations"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/workshops/:workshop_id/sessions/:session_id/registrations" do
    it "holds a registration for an existing attendee when the session has capacity" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      attendee = create(:attendee, name: "Jane Doe", email: "jane@example.com")

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations",
        params: { attendee: { name: attendee.name, email: attendee.email } }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["status"]).to eq("held")
      expect(body["data"]["hold_expires_at"]).to be_present
      expect(body["data"]["attendee_id"]).to eq(attendee.id)
    end

    it "waitlists the registration when the session is full" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 1)
      create(:registration, session: session, status: "held")
      attendee = create(:attendee, name: "New Person", email: "new@example.com")

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations",
        params: { attendee: { name: attendee.name, email: attendee.email } }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["status"]).to eq("waitlisted")
      expect(body["data"]["hold_expires_at"]).to be_nil
    end

    it "reuses an existing attendee (case-insensitive email) instead of creating a duplicate" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      existing = create(:attendee, name: "Existing Person", email: "existing@example.com")

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations",
        params: { attendee: { name: "Ignored Name", email: "EXISTING@example.com" } }

      expect(response).to have_http_status(:created)
      expect(Attendee.count).to eq(1)
      body = JSON.parse(response.body)
      expect(body["data"]["attendee_id"]).to eq(existing.id)
    end

    it "returns a conflict error when the attendee already has an active registration for the session" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      attendee = create(:attendee, email: "dup@example.com")
      create(:registration, attendee: attendee, session: session, status: "held")

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations",
        params: { attendee: { name: attendee.name, email: attendee.email } }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("registration_conflict")
      expect(body["error"]["message"]).to eq("The attendee already has an active registration for this session.")
      expect(body["error"]["details"]).to eq([])
    end

    it "returns a not_found error when no attendee matches the given email" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations",
        params: { attendee: { name: "A", email: "unknown@example.com" } }

      expect(response).to have_http_status(:not_found)
    end

    it "returns a bad_request validation error when the attendee payload is missing entirely" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations"

      expect(response).to have_http_status(:bad_request)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("validation_error")
    end

    it "returns a not_found error for an unknown session" do
      workshop = create(:workshop)

      post "/api/v1/workshops/#{workshop.id}/sessions/999999/registrations",
        params: { attendee: { name: "A", email: "a@example.com" } }

      expect(response).to have_http_status(:not_found)
    end
  end
end
