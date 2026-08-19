class Api::V1::AuthController < Api::V1::BaseController
  before_action :authenticate_user!, only: [ :me, :logout ]

  # POST /api/v1/auth/register
  def register
    user = User.new(register_user_params)
    user.role = "attendee"

    attendee = Attendee.find_by_email(user.email)
    attendee ||= Attendee.new(name: user.name, email: user.email)
    user.attendee = attendee

    if attendee_persisted_with_account?(attendee)
      return render_error(code: "already_registered", message: I18n.t("errors.already_registered"), status: :unprocessable_entity)
    end

    if attendee.save && user.save
      token = AuthToken.issue_for(user)

      response = Response::ResponseData.new(
        data: api_session_payload(token, user),
        message: I18n.t("success.creation", model: User.model_name.human),
        status: :created
      )
      return render json: response.as_json, status: response.status
    end

    response = Response::ResponseError.new(
      code: "creation_conflict",
      message: I18n.t("errors.create_error", model: User.model_name.human),
      details: (user.errors.full_messages + attendee.errors.full_messages).uniq,
      status: :unprocessable_entity
    )
    render json: response.as_json, status: response.status
  end

  # POST /api/v1/auth/login
  def login
    user = User.find_by_email(params[:email].to_s)

    if user&.authenticate(params[:password].to_s)
      token = AuthToken.issue_for(user)

      response = Response::ResponseData.new(
        data: api_session_payload(token, user),
        message: I18n.t("success.response", model: "Session"),
        status: :ok
      )
      render json: response.as_json, status: response.status
    else
      render_error(code: "invalid_credentials", message: I18n.t("errors.invalid_credentials"), status: :unauthorized)
    end
  end

  # DELETE /api/v1/auth/logout
  def logout
    current_token&.revoke!
    render json: { message: I18n.t("success.response", model: "Session"), data: { revoked: true }, status: :ok }, status: :ok
  end

  # GET /api/v1/auth/me
  def me
    response = Response::ResponseData.new(
      data: serialize_user(current_user),
      message: I18n.t("success.response", model: User.model_name.human),
      status: :ok
    )
    render json: response.as_json, status: response.status
  end

  private

  def register_user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def attendee_persisted_with_account?(attendee)
    attendee.persisted? && User.exists?(attendee_id: attendee.id)
  end

  def api_session_payload(token, user)
    {
      token: token,
      user: serialize_user(user)
    }
  end

  def serialize_user(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      attendee_id: user.attendee_id
    }
  end
end