
class Response::SessionSerializer
  def initialize(session, include_availability: false)
    @session = session
    @include_availability = include_availability
  end

  def as_json(*)
    return {} if @session.nil?

    json = {
      id: @session.id,
      workshop_id: @session.workshop_id,
      workshop_title: @session.workshop.title,
      starts_at: @session.starts_at&.iso8601,
      ends_at: @session.ends_at&.iso8601,
      capacity: @session.capacity,
      status: @session.status
    }

    if @include_availability
      json.merge!({
        held_seats: @session.held_seats,
        confirmed_seats: @session.confirmed_seats,
        waitlist_size: @session.waitlist_size,
        available_seats: @session.available_seats
      })
    end

    json
  end
end
