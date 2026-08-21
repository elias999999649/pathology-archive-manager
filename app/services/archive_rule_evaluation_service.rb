class ArchiveRuleEvaluationService
  def self.call(slide, actor: nil)
    new(slide, actor: actor).call
  end

  def initialize(slide, actor: nil)
    @slide = slide
    @actor = actor
  end

  def call
    matches = ArchiveRule.enabled_for_evaluation.filter_map do |rule|
      result = evaluate_rule(rule)
      result[:matched] ? { rule: rule, conditions: result[:conditions] } : nil
    end
    winning = matches.first
    interpreted = winning ? ArchiveRuleActionInterpreter.call(winning[:rule].actions) : { final_decision: "undecided", retention_period: nil, other_actions: [], reason: "No enabled archive rule matched the slide." }
    evaluation = RuleEvaluation.create!(
      slide: slide,
      winning_rule: winning&.fetch(:rule),
      matched_rule_ids: matches.map { |match| match[:rule].id },
      final_decision: interpreted[:final_decision],
      retention_period: interpreted[:retention_period],
      reason: winning ? "Rule #{winning[:rule].name} won with priority #{winning[:rule].priority}. #{interpreted[:reason]}" : interpreted[:reason],
      details: explanation(matches, winning, interpreted),
      evaluated_at: Time.current
    )
    schedule_retention(evaluation, winning)
    AuditLogger.record!(event_type: "archive_rule.evaluated", auditable: evaluation, actor: actor, metadata: { matched_rule_ids: evaluation.matched_rule_ids, winning_rule_id: evaluation.winning_rule_id, final_decision: evaluation.final_decision })
    evaluation
  end

  private

  attr_reader :slide, :actor

  def evaluate_rule(rule)
    definition = rule.conditions.stringify_keys
    group_results = definition.fetch("groups", []).map do |group|
      results = group.fetch("conditions", []).map { |condition| ArchiveRuleConditionEvaluator.call(slide, condition) }
      matched = group["logic"].to_s == "or" ? results.any? { |result| result[:matched] } : results.all? { |result| result[:matched] }
      { logic: group["logic"], matched: matched, conditions: results }
    end
    matched = definition["logic"].to_s == "or" ? group_results.any? { |group| group[:matched] } : group_results.all? { |group| group[:matched] }
    { matched: matched, conditions: group_results }
  end

  def explanation(matches, winning, interpreted)
    {
      "matched_rules" => matches.map { |match| { "id" => match[:rule].id, "name" => match[:rule].name, "priority" => match[:rule].priority, "conditions" => match[:conditions] } },
      "winning_rule_id" => winning&.fetch(:rule)&.id,
      "actions" => interpreted[:other_actions],
      "strategy" => "Enabled rules are ordered by priority descending, then UUID ascending. The first match wins."
    }
  end

  def schedule_retention(evaluation, winning)
    return unless winning

    if evaluation.final_decision == "delete_after_retention"
      RetentionScheduler.schedule_days!(slide, days: evaluation.retention_period, rule: winning[:rule])
    elsif evaluation.final_decision == "keep_forever"
      RetentionScheduler.schedule_forever!(slide, rule: winning[:rule])
    else
      return
    end

    AuditLogger.record!(event_type: "retention.scheduled", auditable: slide, actor: actor, metadata: { retention_rule_id: winning[:rule].id, retention_expires_at: slide.retention_expires_at&.iso8601, retention_status: slide.retention_status })
  end
end
