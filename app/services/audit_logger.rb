class AuditLogger
  REDACTED = "[REDACTED]".freeze
  SECRET_KEY = /token|secret|password|credential|api[ _-]?key|authorization/i

  def self.record!(event_type:, auditable: nil, actor: nil, metadata: {}, reason: nil, previous_value: nil, new_value: nil)
    details = metadata.to_h.deep_dup
    details["reason"] = reason if reason
    details["previous_value"] = previous_value if previous_value
    details["new_value"] = new_value if new_value

    AuditLog.create!(
      event_type: event_type,
      actor: actor,
      auditable_type: auditable&.class&.name,
      auditable_id: auditable&.id,
      metadata: redact(details)
    )
  end

  def self.redact(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, nested), redacted|
        redacted[key.to_s] = key.to_s.match?(SECRET_KEY) ? REDACTED : redact(nested)
      end
    when Array
      value.map { |nested| redact(nested) }
    else
      value
    end
  end
  private_class_method :redact
end
