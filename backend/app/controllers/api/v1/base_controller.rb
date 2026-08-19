class Api::V1::BaseController < ApplicationController
  attr_reader :current_token

  rescue_from ActiveRecord::RecordNotFound do
    render_error(code: "not_found", message: I18n.t("errors.response_not_found", model: "Resource"), status: :not_found)
  end

  private

  def current_user
    @current_user ||= authenticate_token
  end

  def authenticate_token
    token = request.authorization&.match(/\ABearer (.+)\z/)&.captures&.first
    return nil if token.blank?

    auth_token = AuthToken.authenticate(token)
    @current_token = auth_token
    auth_token&.user
  end

  def authenticate_user!
    unless current_user
      render_error(code: "unauthorized", message: I18n.t("errors.unauthorized"), status: :unauthorized)
    end
  end

  def authenticate_admin!
    authenticate_user!
    return if performed?

    unless current_user.admin?
      render_error(code: "forbidden", message: I18n.t("errors.forbidden"), status: :forbidden)
    end
  end

  def render_error(code:, message:, status:)
    response = Response::ResponseError.new(
      code: code,
      message: message,
      details: [],
      status: status
    )

    render json: response.as_json, status: response.status
  end
end