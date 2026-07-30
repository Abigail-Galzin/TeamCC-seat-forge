class Api::V1::SessionsController < ApplicationController
  before_action :set_workshop

  # POST /api/v1/workshops/:workshop_id/sessions
  def create
    @session = @workshop.sessions.new(session_params)

    if @session.save
      render json: @session, status: :created
    else
      render json: @session.errors, status: :unprocessable_entity
    end
  end

  private

  def set_workshop
    @workshop = Workshop.find(params[:workshop_id])
  end

  def session_params
    params.require(:session).permit(:starts_at, :ends_at, :capacity, :status)
  end
end
