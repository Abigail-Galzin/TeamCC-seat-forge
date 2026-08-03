class Api::V1::AttendeesController < ApplicationController
  before_action :set_attendee, only: [ :show, :registrations ]

  # GET /api/v1/attendees?page=1&per_page=10
  def index
    attendees = Attendee.all.order(:name)
    attendees = attendees.where("LOWER(email) = ?", params[:email].to_s.downcase) if params[:email].present?

    @pagy, @attendees = pagy(attendees, items: per_page)

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

  # GET /api/v1/attendees/:id/registrations?page=1&per_page=10
  # Lists the sessions (via their registrations) this attendee has registered for, most recent
  # first, alongside real-time registration counts by status across *all* of the attendee's
  # registrations (not just the current page).
  def registrations
    @pagy, @registrations = pagy(
      @attendee.registrations.includes(session: :workshop).order(created_at: :desc),
      items: per_page
    )

    resp = Response::ResponseData.new(
      data: @registrations.as_json(
        except: [ :created_at, :updated_at ],
        include: {
          session: {
            only: [ :id, :starts_at, :ends_at, :capacity, :status ],
            include: { workshop: { only: [ :id, :title, :topic ] } }
          }
        }
      ),
      message: I18n.t('success.response', model: Registration.model_name.human.pluralize)
    )
    render json: resp.as_json
      .merge(Response::ResponsePaginationInfo.new(@pagy).as_json)
      .merge(status_counts: @attendee.registration_status_counts),
      status: resp.status
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

  def registration_params
    params.require(:registration).permit(:attendee_id)
  end

  def find_attendee
    Attendee.find(registration_params[:attendee_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: I18n.t('errors.response_not_found', model: 'Attendee') }, status: :not_found
    nil
  end
end
