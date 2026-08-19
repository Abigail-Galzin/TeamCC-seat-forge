class Api::V1::WorkshopsController < Api::V1::BaseController
  before_action :set_workshop, only: [ :show, :update ]
  before_action :authenticate_admin!, only: [ :create, :update ]

  def index
    workshops = Workshop.includes(:sessions)
    workshops = workshops.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params[:active].present?

    pagy, records = pagy(workshops, items: per_page)
    response = Response::ResponseData.new(
      data: records.as_json(
        except: [:created_at, :updated_at],
        include: { sessions: { only: [:starts_at, :ends_at, :capacity, :status ]}}
      ),
      message: I18n.t('success.response', model: Workshop.model_name.human.pluralize),
      status: :ok
    )

    render json: response.as_json.merge(Response::ResponsePaginationInfo.new(pagy).as_json),
      status: response.status
  end

  # GET /api/v1/workshops/:id
  def show
    response = Response::ResponseData.new(
      data: @workshop.as_json(
        except: [:created_at, :updated_at],
        include: { sessions: { only: [:starts_at, :ends_at, :capacity, :status ]}}
      ),
      message: I18n.t('success.response', model: Workshop.model_name.human),
      status: :ok
    )

    render json: response.as_json, status: response.status
  end

  # POST /api/v1/workshops
  def create
    workshop = Workshop.new(workshop_params)

    if workshop.save
      response = Response::ResponseData.new(
        data: workshop.as_json(
          include: { sessions: { only: [:starts_at, :ends_at, :capacity, :status ]}}
        ),
        message: I18n.t('success.creation', model: Workshop.model_name.human),
        status: :created
      )

      render json: response.as_json, status: response.status
    else
      response = Response::ResponseError.new(
        code: "creation_conflict",
        message: I18n.t('errors.create_error', model: Workshop.model_name.human),
        details: workshop.errors.full_messages,
        status: :unprocessable_entity
      )

      return render json: response.as_json, status: response.status
    end
  end

  # PATCH/PUT /api/v1/workshops/:id
  def update
    if @workshop.update(workshop_params)
      response = Response::ResponseData.new(
        data: @workshop.as_json(
          include: { sessions: { only: [:starts_at, :ends_at, :capacity, :status ]}}
        ),
        message: I18n.t('success.response', model: Workshop.model_name.human),
        status: :ok
      )

      render json: response.as_json, status: response.status
    else
      response = Response::ResponseError.new(
        code: "update_conflict",
        message: I18n.t('errors.update_error', model: Workshop.model_name.human),
        details: @workshop.errors.full_messages,
        status: :unprocessable_entity
      )

      render json: response.as_json, status: response.status
    end
  end

  private

  def set_workshop
    @workshop = Workshop.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: I18n.t('errors.response_not_found', model: 'Workshop') }, status: :not_found
  end

  def workshop_params
    params.require(:workshop).permit(:title, :description, :topic, :active)
  end
end
