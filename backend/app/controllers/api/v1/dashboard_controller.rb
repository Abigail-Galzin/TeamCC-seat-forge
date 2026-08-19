class Api::V1::DashboardController < Api::V1::BaseController
  before_action :set_workshop, only: [ :show ]
  before_action :authenticate_admin!, only: [ :show ]

  # GET /api/v1/dashboard
  def index
    workshops = Workshop.where(active: true).order(:title)

    data = workshops.map do |workshop|
      {
        id: workshop.id,
        title: workshop.title,
        topic: workshop.topic,
        description: workshop.description,
        current_session: session_summary(workshop.current_or_next_session)
      }
    end

    response = Response::ResponseData.new(
      data: data,
      message: I18n.t('success.response', model: 'Dashboard'),
      status: :ok
    )

    render json: response.as_json, status: response.status
  end

  # GET /api/v1/workshops/:workshop_id/dashboard
  def show
    data = Workshops::DashboardQuery.new(@workshop).call

    response = Response::ResponseData.new(
      data: data,
      message: I18n.t('success.response', model: 'Dashboard'),
      status: :ok
    )

    render json: response.as_json, status: response.status
  end

  private

  def set_workshop
    @workshop = Workshop.find(params[:workshop_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: I18n.t('errors.response_not_found', model: 'Workshop') }, status: :not_found
  end

  def session_summary(session)
    return nil if session.nil?

    {
      id: session.id,
      starts_at: session.starts_at.iso8601,
      ends_at: session.ends_at.iso8601,
      capacity: session.capacity,
      available_seats: session.available_seats,
      in_progress: session.in_progress?
    }
  end
end
