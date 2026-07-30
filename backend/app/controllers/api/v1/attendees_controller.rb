class Api::V1::AttendeesController < ApplicationController
  before_action :set_attendee, only: [ :show ]

  # GET /api/v1/attendees
  def index
    @pagy, @attendees = pagy(Attendee.all, limit: 10)

    resp = Response::ResponseData.new(
      data: @attendees.as_json(except: [ :created_at, :updated_at ]),
      message: I18n.t('success.response', model: Attendee.model_name.human.pluralize)
    )
    render json: resp.as_json.merge(Response::ResponsePaginationInfo.new(@pagy).as_json), status: resp.status
  end

  # GET /api/v1/attendees/:id
  def show
    resp = Response::ResponseData.new(
      data: @attendee.as_json(except: [ :created_at, :updated_at ]),
      message: I18n.t('success.response', model: Attendee.model_name.human)
    )
    render json: resp.as_json, status: resp.status
  end

  # POST /api/v1/attendees
  def create
    @attendee = Attendee.new(attendee_params)

    if @attendee.save
      resp = Response::ResponseData.new(
        data: @attendee.as_json(except: [ :created_at, :updated_at ]),
        message: I18n.t('success.response', model: Attendee.model_name.human),
        status: :created
      )
      render json: resp.as_json, status: resp.status
    else
      response = Response::ResponseError.new(
        code: "creation_conflict",
        message: I18n.t('errors.create_error', model: Attendee.model_name.human),
        details: @attendee.errors.full_messages,
        status: :unprocessable_entity
      )

      render json: response.as_json, status: response.status
    end
  end

  private

  def set_attendee
    @attendee = Attendee.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: I18n.t('errors.response_not_found', model: 'Attendee') }, status: :not_found
  end

  def attendee_params
    params.require(:attendee).permit(:name, :email)
  end
end
