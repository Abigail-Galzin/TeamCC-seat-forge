class Api::V1::WorkshopsController < ApplicationController

  def index
    workshops = Workshop.includes(:sessions).where(active: true)

    pagy, records = pagy(workshops, limit: 10)
    response = Response::ResponseData.new(
      data: workshops.as_json(
        except: [:created_at, :updated_at],
        include: { sessions: { only: [:starts_at, :ends_at, :capacity, :status ]}}
      ),
      message: I18n.t('success.response', model: Workshop.model_name.human.pluralize),
      status: :ok
    )

    render json: response.as_json.merge(Response::ResponsePaginationInfo.new(pagy).as_json),
      status: response.status
  end

  # POST /api/v1/workshops
  def create
    @workshop = Workshop.new(workshop_params)

    if @workshop.save
      response = Response::ResponseData.new(
        data: @workshop.as_json(
          include: { sessions: { only: [:starts_at, :ends_at, :capacity, :status ]}}
        ),
        message: I18n.t('success.creation', model: Workshop.model_name.human),
        status: :created
      )

      render json: response.as_json, status: response.status
    else
      render json: { errors: @workshop.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  def workshop_params
    params.require(:workshop).permit(:title, :description, :topic)
  end
end
