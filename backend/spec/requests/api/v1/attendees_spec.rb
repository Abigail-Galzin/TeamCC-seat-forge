require 'rails_helper'

RSpec.describe "Api::V1::Attendees", type: :request do
  describe "GET /api/v1/attendees" do
    it "lists attendees ordered by name" do
      create(:attendee, name: "Zoe", email: "zoe@example.com")
      create(:attendee, name: "Ana", email: "ana@example.com")

      get "/api/v1/attendees"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |a| a["name"] }).to eq(%w[Ana Zoe])
    end

    it "paginates with the default page size and returns the second page when requested" do
      13.times { |n| create(:attendee, name: "Attendee #{('A'..'Z').to_a[n]}") }

      get "/api/v1/attendees"
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(10)
      expect(body["pagination"]).to include("page" => 1, "count" => 13, "limit" => 10, "pages" => 2)

      get "/api/v1/attendees", params: { page: 2 }
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(3)
      expect(body["pagination"]["page"]).to eq(2)
    end

    it "respects a valid per_page param, capped at the app-wide Pagy default" do
      15.times { create(:attendee) }

      get "/api/v1/attendees", params: { per_page: 5 }
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(5)
      expect(body["pagination"]["limit"]).to eq(5)

      get "/api/v1/attendees", params: { per_page: 1000 }
      body = JSON.parse(response.body)
      expect(body["pagination"]["limit"]).to eq(Pagy::DEFAULT[:items])
    end
  end

  describe "GET /api/v1/attendees/:id" do
    it "returns the attendee" do
      attendee = create(:attendee, name: "Jane Doe", email: "jane@example.com")

      get "/api/v1/attendees/#{attendee.id}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]).to include("id" => attendee.id, "name" => "Jane Doe", "email" => "jane@example.com")
    end

    it "returns a not_found error for an unknown attendee" do
      get "/api/v1/attendees/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/attendees" do
    it "creates an attendee" do
      post "/api/v1/attendees", params: { attendee: { name: "New Attendee", email: "new@example.com" } }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]).to include("name" => "New Attendee", "email" => "new@example.com")
    end

    it "returns a conflict error when validation fails" do
      post "/api/v1/attendees", params: { attendee: { name: "", email: "not-an-email" } }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("creation_conflict")
    end
  end

  describe "GET /api/v1/attendees/:id/registrations" do
    it "lists the attendee's registrations, most recent first, with session and workshop details" do
      attendee = create(:attendee)
      workshop = create(:workshop)
      older_session = create(:session, workshop: workshop, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
      newer_session = create(:session, workshop: workshop, starts_at: 3.days.from_now, ends_at: 3.days.from_now + 1.hour)
      older = create(:registration, attendee: attendee, session: older_session, status: "confirmed", created_at: 2.days.ago)
      newer = create(:registration, attendee: attendee, session: newer_session, status: "held", created_at: 1.hour.ago)

      get "/api/v1/attendees/#{attendee.id}/registrations"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |r| r["id"] }).to eq([ newer.id, older.id ])
      expect(body["data"].last["session"]["workshop"]["id"]).to eq(workshop.id)
    end

    it "does not include another attendee's registrations" do
      attendee = create(:attendee)
      other_attendee = create(:attendee)
      session = create(:session)
      create(:registration, attendee: other_attendee, session: session)

      get "/api/v1/attendees/#{attendee.id}/registrations"

      body = JSON.parse(response.body)
      expect(body["data"]).to eq([])
    end

    it "paginates with the default page size" do
      attendee = create(:attendee)
      12.times do |n|
        session = create(:session, starts_at: (n + 1).days.from_now, ends_at: (n + 1).days.from_now + 1.hour)
        create(:registration, attendee: attendee, session: session)
      end

      get "/api/v1/attendees/#{attendee.id}/registrations"

      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(10)
      expect(body["pagination"]).to include("page" => 1, "count" => 12, "limit" => 10, "pages" => 2)
    end

    it "returns a not_found error for an unknown attendee" do
      get "/api/v1/attendees/999999/registrations"

      expect(response).to have_http_status(:not_found)
    end

    it "includes real-time registration counts by status, covering all of the attendee's registrations regardless of the current page" do
      attendee = create(:attendee)
      create(:registration, attendee: attendee, status: "held",
        session: create(:session, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour))
      create(:registration, attendee: attendee, status: "confirmed",
        session: create(:session, starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour))
      create(:registration, attendee: attendee, status: "confirmed",
        session: create(:session, starts_at: 3.days.from_now, ends_at: 3.days.from_now + 1.hour))
      create(:registration, attendee: attendee, status: "cancelled",
        session: create(:session, starts_at: 4.days.from_now, ends_at: 4.days.from_now + 1.hour))

      get "/api/v1/attendees/#{attendee.id}/registrations", params: { per_page: 2 }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(2)
      expect(body["status_counts"]).to eq(
        "held" => 1,
        "confirmed" => 2,
        "waitlisted" => 0,
        "cancelled" => 1,
        "expired" => 0
      )
    end
  end
end
