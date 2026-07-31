module Paginatable
  extend ActiveSupport::Concern

  private

  def per_page
    requested = params[:per_page].presence&.to_i
    return Pagy::DEFAULT[:items] if requested.blank? || requested < 1

    [ requested, Pagy::DEFAULT[:items] ].min
  end
end
