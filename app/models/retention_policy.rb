class RetentionPolicy < ApplicationRecord
  UNITS = %w[days months years forever].freeze
  PRESETS = {
    "30_days" => ["30 days", "days", 30], "60_days" => ["60 days", "days", 60], "90_days" => ["90 days", "days", 90],
    "6_months" => ["6 months", "months", 6], "1_year" => ["1 year", "years", 1], "5_years" => ["5 years", "years", 5],
    "10_years" => ["10 years", "years", 10], "forever" => ["Forever", "forever", nil]
  }.freeze

  has_many :slides, dependent: :restrict_with_exception

  validates :code, :name, :duration_unit, presence: true
  validates :code, uniqueness: true
  validates :duration_unit, inclusion: { in: UNITS }
  validates :duration_value, numericality: { only_integer: true, greater_than: 0 }, unless: :forever?
  validates :duration_value, absence: true, if: :forever?

  def forever? = duration_unit == "forever"

  def self.preset(code)
    name, unit, value = PRESETS.fetch(code.to_s)
    new(code: code, name: name, duration_unit: unit, duration_value: value)
  end
end
