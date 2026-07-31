module Sessions
  class FilterQuery
    def initialize(params = {})
      @params = params
    end

    def call
      relation = Session.all
      relation = apply_status_filter(relation)
      relation = apply_workshop_filter(relation)
      relation = apply_starts_after_filter(relation)
      relation = apply_ends_before_filter(relation)
      relation = apply_topic_filter(relation)
      relation = apply_available_filter(relation)
      relation = apply_order(relation)
      relation
    end

    private

    attr_reader :params

    def apply_status_filter(relation)
      return relation unless params[:status].present?

      valid_statuses = Session.statuses.keys
      return relation unless valid_statuses.include?(params[:status])

      relation.where(status: params[:status])
    end

    def apply_workshop_filter(relation)
      return relation unless params[:workshop_id].present?
      relation.where(workshop_id: params[:workshop_id])
    end

    def apply_starts_after_filter(relation)
      return relation unless params[:starts_after].present?
      begin
        date = Time.zone.parse(params[:starts_after])
        relation.where('starts_at >= ?', date)
      rescue ArgumentError
        relation
      end
    end

    def apply_ends_before_filter(relation)
      return relation unless params[:ends_before].present?
      begin
        date = Time.zone.parse(params[:ends_before])
        relation.where('ends_at <= ?', date)
      rescue ArgumentError
        relation
      end
    end

    def apply_topic_filter(relation)
      return relation unless params[:topic].present?
      relation.joins(:workshop).where('LOWER(workshops.topic) = ?', params[:topic].to_s.downcase)
    end

    def apply_available_filter(relation)
      return relation unless ActiveModel::Type::Boolean.new.cast(params[:available])
      relation.where("sessions.capacity - (#{confirmed_count_subquery}) > 0")
    end

    def apply_order(relation)
      if params[:sort] == 'available_seats'
        relation.order(Arel.sql("(sessions.capacity - (#{confirmed_count_subquery})) ASC"))
      else
        relation.order(starts_at: :asc)
      end
    end

    # Confirmed seats aren't counter-cached, so availability is computed on the fly via a
    # correlated subquery — matches Session#available_seats (capacity - confirmed_seats).
    def confirmed_count_subquery
      "SELECT COUNT(*) FROM registrations WHERE registrations.session_id = sessions.id AND registrations.status = 'confirmed'"
    end
  end
end
