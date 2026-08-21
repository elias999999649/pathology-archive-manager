class RetentionExpirationService
  def self.call(as_of: Time.current, actor: nil)
    count = 0
    Slide.scheduled_for_retention.where("retention_expires_at <= ?", as_of).find_each do |slide|
      changes = { retention_status: "eligible_for_deletion" }
      changes[:deletion_status] = "eligible_for_trash" if slide.deletion_status_scheduled?
      slide.update!(changes)
      AuditLogger.record!(event_type: "retention.expired", auditable: slide, actor: actor, metadata: { retention_expires_at: slide.retention_expires_at.iso8601, retention_rule_id: slide.retention_rule_id, status: "eligible_for_deletion", deletion_status: slide.deletion_status })
      count += 1
    end
    count
  end
end
