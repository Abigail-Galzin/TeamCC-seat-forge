require 'rails_helper'

RSpec.describe "Api::V1::Workshops", type: :request do
  describe "GET /api/v1/workshops" do
    it "lists only active workshops" do
      active = create(:workshop, title: "Active Workshop", active: true)
      create(:workshop, title: "Inactive Workshop", active: false)

      get "/api/v1/workshops"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |w| w["id"] }).to eq([ active.id ])
    end

    it "includes each workshop's sessions" do
      workshop = create(:workshop, active: true)
      session = create(:session, workshop: workshop, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)

      get "/api/v1/workshops"

      body = JSON.parse(response.body)
      sessions = body["data"].first["sessions"]
      expect(sessions.length).to eq(1)
      expect(sessions.first).to include("capacity" => session.capacity, "status" => session.status)
    end

    it "paginates with the default page size" do
      13.times { |n| create(:workshop, title: "Workshop #{n}", active: true) }

      get "/api/v1/workshops"

      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(10)
      expect(body["pagination"]).to include("page" => 1, "count" => 13, "limit" => 10, "pages" => 2)
    end
  end

  describe "POST /api/v1/workshops" do
    it "creates a workshop" do
      post "/api/v1/workshops", params: {
        workshop: { title: "New Workshop", description: "A description", topic: "Testing", active: true }
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]).to include("title" => "New Workshop", "topic" => "Testing")
    end

    it "returns a conflict error when validation fails" do
      post "/api/v1/workshops", params: {
        workshop: { title: "ab", description: "A description", topic: "Testing", active: true }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("creation_conflict")
      expect(body["error"]["details"]).to be_present
    end

    it "returns a bad_request validation error when the workshop payload is missing entirely" do
      post "/api/v1/workshops"

      expect(response).to have_http_status(:bad_request)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("validation_error")
    end
  end
end
