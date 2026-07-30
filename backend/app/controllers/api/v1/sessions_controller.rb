class Api::V1::SessionsController < ApplicationController
  before_action :set_workshop, only: [:create, :index]
  before_action :set_session, only: [:show, :availability]

  # GET /api/v1/sessions
  def index
    filter_query = Sessions::FilterQuery.new(filter_params)
    sessions = filter_query.call

    pagy, records = pagy(sessions)

    response = Response::ResponseData.new(
      data: records.map {
        |session| Response::SessionSerializer.new(session, include_availability: false).as_json
      },
      message: I18n.t('success.response', model: Session.model_name.human.pluralize),
      status: :ok
    )

    render json: response.as_json.merge(Response::ResponsePaginationInfo.new(pagy).as_json),
      status: response.status
  end

  # POST /api/v1/workshops/:workshop_id/sessions
  def create
    @session = @workshop.sessions.new(session_params)

    if @session.save
      session_data = Response::SessionSerializer.new(@session, include_availability: false).as_json

      response = Response::ResponseData.new(
        data: session_data,
        message: I18n.t('success.creation', model: Session.model_name.human),
        status: :created
      )

      render json: response.as_json, status: response.status
    else
      response = Response::ResponseError.new(
        code: "creation_conflict",
        message: I18n.t('errors.create_error', model: Session.model_name.human),
        details: @session.errors.full_messages,
        status: :unprocessable_entity
      )

      render json: response.as_json, status: response.status
    end
  end

  # GET /api/v1/sessions/:id
  def show
    session_data = Response::SessionSerializer.new(@session, include_availability: false).as_json

    response = Response::ResponseData.new(
      data: session_data,
      message: I18n.t('success.response', model: Session.model_name.human),
      status: :ok
    )

    render json: response.as_json, status: response.status
  end

  # GET /api/v1/sessions/:id/availability
  def availability
    response = Response::ResponseData.new(
      data: {
        id: @session.id,
        held_seats: @session.held_seats,
        confirmed_seats: @session.confirmed_seats,
        waitlist_size: @session.waitlist_size,
        available_seats: @session.available_seats,
        capacity: @session.capacity
      },
      message: I18n.t('success.response', model: 'Availability'),
      status: :ok
    )

    render json: response.as_json, status: response.status
  end

  private

  def set_workshop
    @workshop = Workshop.find(params[:workshop_id]) if params[:workshop_id].present?
  end

  def set_session
    @session = Session.find(params[:id])
  end

  def session_params
    params.require(:session).permit(:starts_at, :ends_at, :capacity, :status)
  end

  def filter_params
    params.permit(:status, :workshop_id, :starts_after, :ends_before, :page, :per_page)
  end
end
