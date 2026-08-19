require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/register" do
    it "creates an attendee account with a linked attendee and returns a token" do
      expect {
        post "/api/v1/auth/register", params: {
          user: { name: "New Person", email: "new@example.com", password: "password123", password_confirmation: "password123" }
        }
      }.to change(User, :count).by(1).and change(Attendee, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["token"]).to be_present
      expect(body["data"]["user"]).to include("email" => "new@example.com", "role" => "attendee")
      expect(body["data"]["user"]["attendee_id"]).to eq(Attendee.find_by_email("new@example.com").id)
    end

    it "links the account to an existing attendee by email instead of creating a duplicate" do
      existing = create(:attendee, name: "Existing", email: "existing@example.com")

      expect {
        post "/api/v1/auth/register", params: {
          user: { name: "Existing", email: "EXISTING@example.com", password: "password123", password_confirmation: "password123" }
        }
      }.to change(User, :count).by(1).and(change(Attendee, :count).by(0))

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["data"]["user"]["attendee_id"]).to eq(existing.id)
    end

    it "rejects an email that already has an account" do
      attendee = create(:attendee, email: "taken@example.com")
      create(:user, email: attendee.email, attendee: attendee)

      post "/api/v1/auth/register", params: {
        user: { name: "Other", email: attendee.email, password: "password123", password_confirmation: "password123" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("already_registered")
    end

    it "rejects an invalid payload" do
      post "/api/v1/auth/register", params: { user: { name: "", email: "bad", password: "123" } }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to eq("creation_conflict")
    end
  end

  describe "POST /api/v1/auth/login" do
    it "returns a token for valid credentials" do
      user = create(:user, email: "login@example.com", password: "password123")

      post "/api/v1/auth/login", params: { email: user.email, password: "password123" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["token"]).to be_present
      expect(body["data"]["user"]["id"]).to eq(user.id)
      expect(body["data"]["user"]["email"]).to eq(user.email)
    end

    it "returns 401 for an invalid password" do
      create(:user, email: "login@example.com", password: "password123")

      post "/api/v1/auth/login", params: { email: "login@example.com", password: "wrong" }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("invalid_credentials")
    end

    it "returns 401 for an unknown email" do
      post "/api/v1/auth/login", params: { email: "nobody@example.com", password: "whatever1" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    it "returns the current user" do
      user = create(:user)

      get "/api/v1/auth/me", headers: bearer_header_for(user)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]).to include("id" => user.id, "email" => user.email, "role" => "attendee")
    end

    it "returns 401 without a token" do
      get "/api/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "revokes the current token" do
      user = create(:user)
      headers = bearer_header_for(user)
      token_record = AuthToken.authenticate(headers["Authorization"].split.last)
      expect(token_record).to be_present

      delete "/api/v1/auth/logout", headers: headers

      expect(response).to have_http_status(:ok)
      expect(token_record.reload.revoked_at).to be_present
      expect(AuthToken.authenticate(headers["Authorization"].split.last)).to be_nil
    end

    it "returns 401 without a token" do
      delete "/api/v1/auth/logout"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "token lifecycle" do
    it "rejects an expired token" do
      user = create(:user)
      token = AuthToken.issue_for(user, expires_at: 1.minute.ago)

      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a revoked token" do
      user = create(:user)
      token = AuthToken.issue_for(user)
      AuthToken.authenticate(token).revoke!

      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end