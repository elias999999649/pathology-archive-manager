class RetentionController < ApplicationController
  def index
    authorize RetentionPolicy
    @days_ahead = 30
    @expiring_slides = Slide.expiring_soon(Time.current + @days_ahead.days).includes(:retention_rule).order(retention_expires_at: :asc)
    @eligible_slides = Slide.eligible_for_deletion.includes(:retention_rule).order(retention_expires_at: :asc)
  end
end
