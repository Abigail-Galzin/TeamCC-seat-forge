class Response::ResponseError
  attr_reader :code, :message, :details, :status

  def initialize(code: nil, message: nil, details: [], status: :unprocessable_entity)
    @code = code
    @message = message
    @details = details
    @status  = status
  end

  def as_json(*)
    {
      error: {
        code: code,
        message: message,
        details: details
      }
    }
  end
end
