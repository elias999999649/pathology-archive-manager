class RetentionCalculator
  Result = Data.define(:started_at, :expires_at)

  def self.call(policy, started_at:)
    started_at = started_at.in_time_zone
    expires_at = if policy.forever?
      nil
    elsif policy.duration_unit == "days"
      started_at + policy.duration_value.days
    elsif policy.duration_unit == "months"
      started_at.advance(months: policy.duration_value)
    elsif policy.duration_unit == "years"
      started_at.advance(years: policy.duration_value)
    end
    Result.new(started_at, expires_at)
  end
end
