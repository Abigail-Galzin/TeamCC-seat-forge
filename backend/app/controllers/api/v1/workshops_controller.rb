class Api::V1::WorkshopsController < ApplicationController


  # POST /api/v1/workshops
  def create
    @workshop = Workshop.new(workshop_params)

    if @workshop.save
      render json: @workshop, status: :created
    else
      render json: @workshop.errors, status: :unprocessable_entity
    end
  end

  private
  def workshop_params
    params.require(:workshop).permit(:title, :description, :topic)
  end
end
