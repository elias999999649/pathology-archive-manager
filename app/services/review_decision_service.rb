class ReviewDecisionService
  Result = Data.define(:review, :slide)

  def self.call(slide, reviewer:, decision:, comment: nil, retention_policy_code: nil, custom_days: nil, tags: [])
    new(slide, reviewer: reviewer, decision: decision, comment: comment, retention_policy_code: retention_policy_code, custom_days: custom_days, tags: tags).call
  end

  def initialize(slide, reviewer:, decision:, comment:, retention_policy_code:, custom_days:, tags:)
    @slide = slide
    @reviewer = reviewer
    @decision = decision.to_s
    @comment = comment.to_s.strip.presence
    @retention_policy_code = retention_policy_code.to_s.presence
    @custom_days = custom_days
    @tags = Array(tags).flat_map { |tag| tag.to_s.split(",") }.map(&:strip).reject(&:blank?).uniq
  end

  def call
    raise Pundit::NotAuthorizedError, "Reviewer is not authorized" unless ReviewPolicy.new(reviewer, slide).update?
    raise ArgumentError, "Slide is not awaiting manual review" unless slide.under_review?
    raise ArgumentError, "Unsupported review decision" unless Review.decisions.key?(decision)

    review = nil
    Slide.transaction do
      previous_state = snapshot
      apply_decision!
      review = Review.create!(slide: slide, reviewer: reviewer, decision: decision, comment: comment, previous_state: previous_state, retention_policy_code: retention_policy_code, tags_added: tags, decided_at: Time.current)
      AuditLogger.record!(event_type: "slide.manual_review_decided", auditable: review, actor: reviewer, metadata: { slide_id: slide.id, decision: decision, previous_state: previous_state, comment: comment, tags_added: tags })
      if decision == "keep" || decision == "delete"
        AuditLogger.record!(event_type: "slide.manual_#{decision}", auditable: slide, actor: reviewer, reason: comment, previous_value: previous_state, new_value: { "decision" => decision, "status" => slide.status })
      end
      if retention_policy_code.present? && retention_policy_code != "none"
        AuditLogger.record!(event_type: "retention.changed", auditable: slide, actor: reviewer, previous_value: previous_state.slice("retention_status", "retention_expires_at"), new_value: { "policy" => retention_policy_code, "retention_expires_at" => slide.retention_expires_at&.iso8601 })
      end
    end
    Result.new(review, slide)
  end

  private

  attr_reader :slide, :reviewer, :decision, :comment, :retention_policy_code, :custom_days, :tags

  def snapshot
    { "status" => slide.status, "decision" => slide.decision, "decision_reason" => slide.decision_reason, "retention_status" => slide.retention_status, "retention_expires_at" => slide.retention_expires_at&.iso8601, "deletion_status" => slide.deletion_status, "tags" => slide.tags }
  end

  def apply_decision!
    slide.update!(decision: decision, status: "available", decision_reason: "Manual review by #{reviewer.email}: #{comment || 'No comment provided.'}", deletion_status: decision == "delete" ? "scheduled" : "none", deletion_scheduled_at: decision == "delete" ? Time.current : nil, tags: (slide.tags + tags).uniq)
    policy = retention_policy
    RetentionScheduler.schedule!(slide, policy: policy, rule: slide.retention_rule, started_at: Time.current) if policy
  end

  def retention_policy
    return RetentionPolicy.new(code: "custom_#{custom_days}_days", name: "#{custom_days} days", duration_unit: "days", duration_value: custom_days.to_i) if retention_policy_code == "custom" && custom_days.to_i.positive?
    return if retention_policy_code.blank? || retention_policy_code == "none"

    RetentionPolicy.preset(retention_policy_code)
  end
end
