class ReviewPolicy < ApplicationPolicy
  def index? = reviewer_or_administrator?
  def show? = reviewer_or_administrator? && reviewable_record?
  def update? = reviewer_or_administrator? && reviewable_record?

  private

  def reviewer_or_administrator?
    user&.reviewer? || user&.system_administrator? || user&.archive_administrator?
  end

  def reviewable_record?
    !record.is_a?(Slide) || record.under_review?
  end
end
