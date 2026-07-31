class Api::V1::RegistrationsController < ApplicationController
  before_action :set_workshop
  before_action :set_session
  before_action :set_registration, only: [ :show, :confirm, :cancel ]

  # GET /api/v1/workshops/:workshop_id/sessions/:session_id/registrations?page=1&per_page=10
  # Lists the attendees selected (registered) for the session, paginated, most recent first.
  def index
    @pagy, @registrations = pagy(
      @session.registrations.includes(:attendee).order(created_at: :desc),
      items: per_page
    )

    resp = Response::ResponseData.new(
      data: @registrations.as_json(
        except: [ :created_at, :updated_at ],
        include: { attendee: { only: [ :id, :name, :email ] } }
      ),
      message: I18n.t('success.response', model: Registration.model_name.human.pluralize)
    )
    render json: resp.as_json.merge(Response::ResponsePaginationInfo.new(@pagy).as_json), status: resp.status
  end

  # GET /api/v1/workshops/:workshop_id/sessions/:session_id/registrations/:id
  def show
    resp = Response::ResponseData.new(
      data: @registration.as_json(except: [ :created_at, :updated_at ]),
      message: I18n.t('success.response', model: Registration.model_name.human)
    )
    render json: resp.as_json, status: resp.status
  end

  # POST /api/v1/workshops/:workshop_id/sessions/:session_id/registrations
  def create
    attendee = find_attendee
    return if attendee.nil?

    @registration = Registration.register(attendee: attendee, session: @session)

    if @registration.persisted?
      resp = Response::ResponseData.new(
        data: @registration.as_json(except: [ :created_at, :updated_at ]),
        message: I18n.t('success.response', model: Registration.model_name.human),
        status: :created
      )
      render json: resp.as_json, status: resp.status
    else
      response = Response::ResponseError.new(
        code: "creation_conflict",
        message: I18n.t('errors.create_error', model: Registration.model_name.human),
        details: @registration.errors.full_messages,
        status: :unprocessable_entity
      )

      render json: response.as_json, status: response.status
    end
  end

  # POST /api/v1/workshops/:workshop_id/sessions/:session_id/registrations/:id/confirm
  def confirm
    if @registration.confirm
      resp = Response::ResponseData.new(
        data: @registration.as_json(except: [ :created_at, :updated_at ]),
        message: I18n.t('success.response', model: Registration.model_name.human)
      )
      render json: resp.as_json, status: resp.status
    else
      response = Response::ResponseError.new(
        code: "confirmation_conflict",
        message: I18n.t('errors.confirm_error', model: Registration.model_name.human),
        details: @registration.errors.full_messages,
        status: :unprocessable_entity
      )

      render json: response.as_json, status: response.status
    end
  end

  # POST /api/v1/workshops/:workshop_id/sessions/:session_id/registrations/:id/cancel
  def cancel
    if @registration.cancel
      resp = Response::ResponseData.new(
        data: @registration.as_json(except: [ :created_at, :updated_at ]),
        message: I18n.t('success.response', model: Registration.model_name.human)
      )
      render json: resp.as_json, status: resp.status
    else
      response = Response::ResponseError.new(
        code: "cancellation_conflict",
        message: I18n.t('errors.cancel_error', model: Registration.model_name.human),
        details: @registration.errors.full_messages,
        status: :unprocessable_entity
      )

      render json: response.as_json, status: response.status
    end
  end

  private

  def set_workshop
    @workshop = Workshop.find(params[:workshop_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: I18n.t('errors.response_not_found', model: 'Workshop') }, status: :not_found
  end

  def set_session
    @session = @workshop.sessions.find(params[:session_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: I18n.t('errors.response_not_found', model: 'Session') }, status: :not_found
  end

  def set_registration
    @registration = @session.registrations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: I18n.t('errors.response_not_found', model: 'Registration') }, status: :not_found
  end

  def attendee_params
    params.require(:attendee).permit(:name, :email)
  end

  def find_attendee
    attendee = Attendee.find_by_email(attendee_params[:email])
    return attendee if attendee

    render json: { error: I18n.t('errors.response_not_found', model: 'Attendee') }, status: :not_found
    nil
  end
end
