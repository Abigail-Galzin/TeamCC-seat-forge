require 'rails_helper'

RSpec.describe "Api::V1::Registrations", type: :request do
  let(:admin) { create(:user, :admin) }

  describe "GET /api/v1/workshops/:workshop_id/sessions/:session_id/registrations" do
    it "lists the attendees registered for the session, most recent first, with attendee details" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 10)
      attendee = create(:attendee, name: "Jane Doe", email: "jane@example.com")
      older = create(:registration, attendee: attendee, session: session, status: "confirmed", created_at: 2.days.ago)
      newer = create(:registration, session: session, status: "held", created_at: 1.hour.ago)

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", headers: bearer_header_for(admin)

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

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", headers: bearer_header_for(admin)

      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(1)
    end

    it "paginates with the default page size" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 30)
      12.times { create(:registration, session: session) }

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", headers: bearer_header_for(admin)

      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(10)
      expect(body["pagination"]).to include("page" => 1, "count" => 12, "limit" => 10, "pages" => 2)
    end

    it "respects a valid per_page param, capped at the app-wide Pagy default" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 60)
      15.times { create(:registration, session: session) }

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", params: { per_page: 5 }, headers: bearer_header_for(admin)
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(5)
      expect(body["pagination"]["limit"]).to eq(5)

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", params: { per_page: 1000 }, headers: bearer_header_for(admin)
      body = JSON.parse(response.body)
      expect(body["pagination"]["limit"]).to eq(Pagy::DEFAULT[:items])
    end

    it "returns a not_found error for an unknown session" do
      workshop = create(:workshop)

      get "/api/v1/workshops/#{workshop.id}/sessions/999999/registrations", headers: bearer_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 for unauthenticated requests" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop)

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 403 for a non-admin attendee" do
      attendee = create(:user)
      workshop = create(:workshop)
      session = create(:session, workshop: workshop)

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", headers: bearer_header_for(attendee)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/workshops/:workshop_id/sessions/:session_id/registrations" do
    it "holds a registration for the authenticated attendee when the session has capacity" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      attendee = create(:attendee, name: "Jane Doe", email: "jane@example.com")
      account = create(:user, email: attendee.email, attendee: attendee)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", headers: bearer_header_for(account)

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
      account = create(:user, email: attendee.email, attendee: attendee)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", headers: bearer_header_for(account)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["status"]).to eq("waitlisted")
      expect(body["data"]["hold_expires_at"]).to be_nil
    end

    it "returns a conflict error when the attendee already has an active registration for the session" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      attendee = create(:attendee, email: "dup@example.com")
      account = create(:user, email: attendee.email, attendee: attendee)
      create(:registration, attendee: attendee, session: session, status: "held")

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations", headers: bearer_header_for(account)

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("registration_conflict")
      expect(body["error"]["message"]).to eq("The attendee already has an active registration for this session.")
      expect(body["error"]["details"]).to eq([])
    end

    it "returns 401 for an unauthenticated request" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations"

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("unauthorized")
    end

    it "returns a not_found error for an unknown session" do
      workshop = create(:workshop)
      attendee = create(:attendee)
      account = create(:user, email: attendee.email, attendee: attendee)

      post "/api/v1/workshops/#{workshop.id}/sessions/999999/registrations", headers: bearer_header_for(account)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/workshops/:workshop_id/sessions/:session_id/registrations/:id" do
    it "returns the registration" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      registration = create(:registration, session: session, status: "held")

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/#{registration.id}", headers: bearer_header_for(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]).to include("id" => registration.id, "status" => "held")
    end

    it "returns a not_found error for an unknown registration" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/999999", headers: bearer_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 for unauthenticated requests" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop)

      get "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/1"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/workshops/:workshop_id/sessions/:session_id/registrations/:id/confirm" do
    it "confirms a held registration" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      registration = create(:registration, session: session, status: "held", hold_expires_at: 5.minutes.from_now)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/#{registration.id}/confirm", headers: bearer_header_for(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["status"]).to eq("confirmed")
      expect(body["data"]["hold_expires_at"]).to be_nil
    end

    it "returns a conflict error when the registration cannot be confirmed" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      registration = create(:registration, session: session, status: "waitlisted", hold_expires_at: nil)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/#{registration.id}/confirm", headers: bearer_header_for(admin)

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("confirmation_conflict")
      expect(registration.reload.status).to eq("waitlisted")
    end

    it "returns a not_found error for an unknown registration" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/999999/confirm", headers: bearer_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 403 for a non-admin attendee" do
      attendee = create(:user)
      workshop = create(:workshop)
      session = create(:session, workshop: workshop)
      registration = create(:registration, session: session, status: "held")

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/#{registration.id}/confirm", headers: bearer_header_for(attendee)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/workshops/:workshop_id/sessions/:session_id/registrations/:id/cancel" do
    it "cancels a held registration" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      registration = create(:registration, session: session, status: "held")

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/#{registration.id}/cancel", headers: bearer_header_for(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["status"]).to eq("cancelled")
    end

    it "promotes the oldest waitlisted registration when a held seat is released" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 1)
      held = create(:registration, session: session, status: "held")
      waitlisted = create(:registration, session: session, status: "waitlisted", created_at: 1.hour.ago)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/#{held.id}/cancel", headers: bearer_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(waitlisted.reload.status).to eq("held")
    end

    it "returns a conflict error when the registration cannot be cancelled" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)
      registration = create(:registration, session: session, status: "expired", hold_expires_at: nil)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/#{registration.id}/cancel", headers: bearer_header_for(admin)

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("cancellation_conflict")
    end

    it "returns a not_found error for an unknown registration" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop, capacity: 5)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/999999/cancel", headers: bearer_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 for unauthenticated requests" do
      workshop = create(:workshop)
      session = create(:session, workshop: workshop)
      registration = create(:registration, session: session)

      post "/api/v1/workshops/#{workshop.id}/sessions/#{session.id}/registrations/#{registration.id}/cancel"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end