require "rails_helper"

RSpec.describe ArchiveRuleEvaluationService do
  let!(:user) { User.create!(email: "evaluator@example.com", password: "password12345", role: :archive_administrator) }
  let!(:slide) { Slide.create!(slide_uid: "UID-1", case_id: "CASE-1", slide_type: "H&E", hospital: "General", received_at: Time.current, metadata: { "source" => "lis" }, tags: ["urgent"]) }
  let(:condition) { { "field" => "slide_type", "operator" => "equals", "value" => "H&E" } }

  def matching_conditions(logic: "and")
    { "logic" => logic, "groups" => [{ "logic" => "and", "conditions" => [condition] }] }
  end

  def create_rule(name:, priority:, enabled: true, decision: "keep", rule_conditions: matching_conditions)
    ArchiveRule.create!(name: name, priority: priority, enabled: enabled, conditions: rule_conditions, actions: [{ "type" => decision }], created_by: user, updated_by: user)
  end

  it "records one matching rule, its decision, winner, and explanation" do
    rule = create_rule(name: "Keep H&E", priority: 10)

    evaluation = described_class.call(slide, actor: user)

    expect(evaluation).to have_attributes(winning_rule: rule, final_decision: "keep", matched_rule_ids: [rule.id])
    expect(evaluation.reason).to include("Keep H&E", "priority 10")
    expect(evaluation.details["matched_rules"].first["conditions"]).to be_present
  end

  it "records an explainable undecided result when nothing matches" do
    create_rule(name: "Keep IHC", priority: 10, rule_conditions: { "logic" => "and", "groups" => [{ "logic" => "and", "conditions" => [{ "field" => "slide_type", "operator" => "equals", "value" => "IHC" }] }] })

    evaluation = described_class.call(slide)

    expect(evaluation).to have_attributes(winning_rule: nil, matched_rule_ids: [], final_decision: "undecided")
    expect(evaluation.reason).to include("No enabled archive rule matched")
  end

  it "uses highest priority and ignores disabled rules" do
    create_rule(name: "Low priority", priority: 1, decision: "delete")
    high = create_rule(name: "High priority", priority: 20, decision: "keep_forever")
    create_rule(name: "Disabled", priority: 100, enabled: false, decision: "delete")

    evaluation = described_class.call(slide)

    expect(evaluation.winning_rule).to eq(high)
    expect(evaluation.final_decision).to eq("keep_forever")
    expect(evaluation.matched_rule_ids).not_to include(ArchiveRule.find_by(name: "Disabled").id)
  end

  it "supports AND within a group and OR within a group" do
    and_conditions = { "logic" => "and", "groups" => [{ "logic" => "and", "conditions" => [condition, { "field" => "hospital", "operator" => "equals", "value" => "General" }] }] }
    or_conditions = { "logic" => "and", "groups" => [{ "logic" => "or", "conditions" => [{ "field" => "slide_type", "operator" => "equals", "value" => "IHC" }, { "field" => "hospital", "operator" => "equals", "value" => "General" }] }] }
    and_rule = create_rule(name: "AND", priority: 20, rule_conditions: and_conditions)
    or_rule = create_rule(name: "OR", priority: 10, rule_conditions: or_conditions)

    evaluation = described_class.call(slide)

    expect(evaluation.matched_rule_ids).to eq([and_rule.id, or_rule.id])
    expect(evaluation.winning_rule).to eq(and_rule)
  end

  it "records conflicting matching rules without ambiguity by using priority" do
    create_rule(name: "Delete low", priority: 5, decision: "delete")
    keep_rule = create_rule(name: "Keep high", priority: 6, decision: "keep")

    evaluation = described_class.call(slide)

    expect(evaluation.final_decision).to eq("keep")
    expect(evaluation.matched_rule_ids.length).to eq(2)
    expect(evaluation.details["strategy"]).to include("priority descending")
  end
end
