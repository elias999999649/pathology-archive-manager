class SlideImportWorkflow
  Result = Data.define(:slide, :evaluation, :errors)

  def self.call(attributes, actor: nil)
    new(attributes, actor: actor).call
  end

  def initialize(attributes, actor: nil)
    @attributes = attributes
    @actor = actor
  end

  def call
    slide = Slide.new(attributes.merge(received_at: attributes[:received_at] || Time.current, status: "received", decision: "undecided"))
    unless slide.valid?
      AuditLogger.record!(event_type: "slide.import_rejected", actor: actor, metadata: { errors: slide.errors.to_hash })
      return Result.new(nil, nil, slide.errors.to_hash)
    end

    evaluation = nil
    Slide.transaction do
      slide.save!
      evaluation = ArchiveRuleEvaluationService.call(slide, actor: actor)
      apply_decision!(slide, evaluation)
      AuditLogger.record!(event_type: "slide.automatic_decision", auditable: slide, actor: actor, metadata: { final_decision: slide.decision, decision_reason: slide.decision_reason, winning_rule_id: evaluation.winning_rule_id, matched_rule_ids: evaluation.matched_rule_ids, deletion_status: slide.deletion_status })
      decision_event = slide.delete? || slide.delete_after_retention? ? "slide.automatic_delete" : (slide.keep? || slide.keep_forever? ? "slide.automatic_keep" : nil)
      AuditLogger.record!(event_type: decision_event, auditable: slide, actor: actor, reason: slide.decision_reason, metadata: { final_decision: slide.decision }) if decision_event
      AuditLogger.record!(event_type: "slide.imported", auditable: slide, actor: actor, metadata: { received_at: slide.received_at.iso8601 })
    end
    Result.new(slide, evaluation, {})
  end

  private

  attr_reader :attributes, :actor

  def apply_decision!(slide, evaluation)
    changes = { decision: evaluation.final_decision, decision_reason: evaluation.reason }
    case evaluation.final_decision
    when "keep", "keep_forever"
      changes[:status] = "available"
    when "manual_review"
      changes[:status] = "under_review"
    when "delete", "delete_after_retention"
      changes[:status] = "available"
      changes[:deletion_status] = "scheduled"
      changes[:deletion_scheduled_at] = Time.current
    else
      changes[:status] = "under_review"
    end
    slide.update!(changes)
  end
end
