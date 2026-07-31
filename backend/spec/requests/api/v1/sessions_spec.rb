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
end
