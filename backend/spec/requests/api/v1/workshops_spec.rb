require 'rails_helper'

RSpec.describe "Api::V1::Workshops", type: :request do
  describe "GET /index" do
    it "returns only active workshops when active=true" do
      active = create(:workshop, active: true)
      create(:workshop, active: false)

      get "/api/v1/workshops", params: { active: true }

      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json["data"].map { |w| w["id"] }).to eq([ active.id ])
    end

    it "returns every workshop when active is omitted" do
      create(:workshop, active: true)
      create(:workshop, active: false)

      get "/api/v1/workshops"

      json = response.parsed_body
      expect(json["data"].length).to eq(2)
    end

    it "paginates using per_page" do
      create_list(:workshop, 3)

      get "/api/v1/workshops", params: { per_page: 1, page: 2 }

      json = response.parsed_body
      expect(json["data"].length).to eq(1)
      expect(json["pagination"]).to include("page" => 2, "pages" => 3, "limit" => 1)
    end
  end

  describe "GET /show" do
    it "returns the workshop" do
      workshop = create(:workshop)

      get "/api/v1/workshops/#{workshop.id}"

      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json["data"]["id"]).to eq(workshop.id)
    end

    it "returns 404 for an unknown workshop" do
      get "/api/v1/workshops/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /create" do
    it "creates a workshop with the given active flag" do
      admin = create(:user, :admin)

      post "/api/v1/workshops", params: { workshop: { title: "New Workshop", description: "Desc", topic: "Testing", active: false } }, headers: bearer_header_for(admin)

      json = response.parsed_body
      expect(response).to have_http_status(:created)
      expect(json["data"]["active"]).to eq(false)
    end

    it "returns validation errors" do
      admin = create(:user, :admin)

      post "/api/v1/workshops", params: { workshop: { title: "", description: "", topic: "" } }, headers: bearer_header_for(admin)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 401 for unauthenticated requests" do
      post "/api/v1/workshops", params: { workshop: { title: "New", description: "Desc", topic: "Topic", active: true } }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("unauthorized")
    end

    it "returns 403 for a non-admin attendee" do
      attendee = create(:user)

      post "/api/v1/workshops", params: { workshop: { title: "New", description: "Desc", topic: "Topic", active: true } }, headers: bearer_header_for(attendee)

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("forbidden")
    end
  end

  describe "PATCH /update" do
    it "updates the workshop" do
      admin = create(:user, :admin)
      workshop = create(:workshop, title: "Old title", active: true)

      patch "/api/v1/workshops/#{workshop.id}", params: { workshop: { title: "New title", description: workshop.description, topic: workshop.topic, active: false } }, headers: bearer_header_for(admin)

      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json["data"]["title"]).to eq("New title")
      expect(json["data"]["active"]).to eq(false)
    end

    it "returns 404 for an unknown workshop" do
      admin = create(:user, :admin)

      patch "/api/v1/workshops/999999", params: { workshop: { title: "x", description: "x", topic: "x", active: true } }, headers: bearer_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "returns validation errors" do
      admin = create(:user, :admin)
      workshop = create(:workshop)

      patch "/api/v1/workshops/#{workshop.id}", params: { workshop: { title: "", description: "", topic: "" } }, headers: bearer_header_for(admin)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 401 for unauthenticated requests" do
      workshop = create(:workshop)

      patch "/api/v1/workshops/#{workshop.id}", params: { workshop: { title: "x", description: "x", topic: "x", active: true } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
