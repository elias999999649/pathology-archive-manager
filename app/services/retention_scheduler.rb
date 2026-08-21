class RetentionScheduler
  def self.schedule!(slide, policy:, rule: nil, started_at: nil)
    result = RetentionCalculator.call(policy, started_at: started_at || slide.received_at)
    slide.update!(
      retention_policy: policy.persisted? ? policy : nil,
      retention_rule: rule,
      retention_started_at: result.started_at,
      retention_expires_at: result.expires_at,
      retention_status: result.expires_at ? "scheduled" : "forever",
      retention_duration: { "unit" => policy.duration_unit, "value" => policy.duration_value, "name" => policy.name },
      retention_period: policy.duration_unit == "days" ? policy.duration_value : nil
    )
    slide
  end

  def self.schedule_days!(slide, days:, rule: nil, started_at: nil)
    policy = RetentionPolicy.new(code: "inline_#{days}_days", name: "#{days} days", duration_unit: "days", duration_value: days)
    schedule!(slide, policy: policy, rule: rule, started_at: started_at)
  end

  def self.schedule_forever!(slide, rule: nil, started_at: nil)
    schedule!(slide, policy: RetentionPolicy.preset("forever"), rule: rule, started_at: started_at)
  end
end
