class ArchiveRuleActionInterpreter
  DECISION_MAP = {
    "keep" => "keep",
    "delete" => "delete",
    "manual_review" => "manual_review",
    "keep_forever" => "keep_forever",
    "delete_after_days" => "delete_after_retention"
  }.freeze

  def self.call(actions)
    actions = actions.map { |action| action.stringify_keys }
    decision_action = actions.find { |action| DECISION_MAP.key?(action["type"].to_s) }
    decision = DECISION_MAP.fetch(decision_action["type"].to_s)
    {
      final_decision: decision,
      retention_period: decision == "delete_after_retention" ? decision_action["days"].to_i : nil,
      other_actions: actions.reject { |action| action.equal?(decision_action) },
      reason: "Winning rule requested #{decision_action['type'].to_s.humanize.downcase}."
    }
  end
end
