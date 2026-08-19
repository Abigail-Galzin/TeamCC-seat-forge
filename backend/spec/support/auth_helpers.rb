module AuthHelpers
  # Issues a live bearer token for the given user and returns the Authorization
  # header value the request specs should send.
  def bearer_header_for(user)
    token = AuthToken.issue_for(user)
    { "Authorization" => "Bearer #{token}" }
  end

  def json_headers
    { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
  end
end