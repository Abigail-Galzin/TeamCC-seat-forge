class ApplicationController < ActionController::API
  include Pagy::Backend

  rescue_from ActionController::ParameterMissing do |exception|
    response = Response::ResponseError.new(
      code: "validation_error",
      message: exception.message,
      details: [],
      status: :bad_request
    )

    render json: response.as_json, status: response.status
  end
end
