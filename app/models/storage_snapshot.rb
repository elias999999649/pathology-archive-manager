class StorageSnapshot < ApplicationRecord
  STATUSES = %w[unconfigured healthy warning_80 warning_90 critical_95 error].freeze

  validates :provider_name, :checked_at, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :total_bytes, :used_bytes, :free_bytes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :usage_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :slide_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :breakdowns_are_objects

  scope :latest_first, -> { order(checked_at: :desc) }

  def warning?
    %w[warning_80 warning_90 critical_95].include?(status)
  end

  def critical?
    status == "critical_95"
  end

  private

  def breakdowns_are_objects
    errors.add(:by_slide_type, "must be a JSON object") unless by_slide_type.is_a?(Hash)
    errors.add(:by_hospital, "must be a JSON object") unless by_hospital.is_a?(Hash)
  end
end
