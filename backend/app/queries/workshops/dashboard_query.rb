module Workshops
  class DashboardQuery
    def initialize(workshop)
      @workshop = workshop
    end

    def call
      {
        workshop_id: workshop.id,
        workshop_title: workshop.title,
        upcoming_sessions: upcoming_sessions_count,
        held_registrations: registration_counts["held"].to_i,
        confirmed_registrations: registration_counts["confirmed"].to_i,
        waitlisted_registrations: registration_counts["waitlisted"].to_i,
        expired_holds_today: expired_holds_today_count,
        full_sessions: full_sessions_count,
        top_waitlisted_sessions: top_waitlisted_sessions
      }
    end

    private

    attr_reader :workshop

    def registration_counts
      @registration_counts ||= scoped_registrations.group(:status).count
    end

    def scoped_registrations
      @scoped_registrations ||= Registration.joins(:session).where(sessions: { workshop_id: workshop.id })
    end

    def upcoming_sessions_count
      workshop.sessions.scheduled.where("starts_at > ?", Time.current).count
    end

    def expired_holds_today_count
      scoped_registrations.where(status: :expired, updated_at: Time.current.all_day).count
    end

    def full_sessions_count
      workshop.sessions.includes(:registrations).count { |session| session.available_seats <= 0 }
    end

    def top_waitlisted_sessions
      counts = scoped_registrations.waitlisted.group(:session_id).count
      top = counts.sort_by { |_, count| -count }.first(3)
      sessions_by_id = Session.where(id: top.map(&:first)).index_by(&:id)

      top.map do |session_id, count|
        session = sessions_by_id[session_id]
        {
          session_id: session_id,
          starts_at: session&.starts_at&.iso8601,
          waitlist_size: count
        }
      end
    end
  end
end
