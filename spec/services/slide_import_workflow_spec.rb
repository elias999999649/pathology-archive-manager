require "rails_helper"

RSpec.describe SlideImportWorkflow do
  let!(:user) { User.create!(email: "workflow@example.com", password: "password12345", role: :archive_administrator) }
  let(:condition) { { "field" => "slide_type", "operator" => "equals", "value" => "H&E" } }
  let(:conditions) { { "logic" => "and", "groups" => [{ "logic" => "and", "conditions" => [condition] }] } }

  def rule(name, decision, priority: 10)
    ArchiveRule.create!(name: name, priority: priority, enabled: true, conditions: conditions, actions: [{ "type" => decision, "days" => decision == "delete_after_days" ? 30 : nil }], created_by: user, updated_by: user)
  end

  it "validates, evaluates, stores, and audits a keep decision" do
    winning_rule = rule("Keep H&E", "keep")

    result = described_class.call({ slide_uid: "IMP-KEEP", case_id: "CASE-1", slide_type: "H&E" }, actor: user)

    expect(result.errors).to be_empty
    expect(result.slide).to have_attributes(decision: "keep", status: "available", decision_reason: include(winning_rule.name))
    expect(result.evaluation.winning_rule).to eq(winning_rule)
    expect(AuditLog.where(event_type: "slide.automatic_decision", auditable_id: result.slide.id)).to exist
  end

  it "routes manual review decisions to under review" do
    rule("Needs review", "manual_review")

    result = described_class.call({ slide_uid: "IMP-REVIEW", case_id: "CASE-2", slide_type: "H&E" })

    expect(result.slide).to have_attributes(decision: "manual_review", status: "under_review")
  end

  it "schedules delete eligibility without deleting the slide" do
    winning_rule = rule("Delete H&E", "delete")

    result = described_class.call({ slide_uid: "IMP-DELETE", case_id: "CASE-3", slide_type: "H&E" })

    expect(result.slide).to have_attributes(decision: "delete", deletion_status: "scheduled", retention_status: "not_scheduled", retention_rule: nil)
    expect(result.slide.deletion_scheduled_at).to be_present
    expect(result.slide.reload).to be_persisted
    expect(result.evaluation.winning_rule).to eq(winning_rule)
  end

  it "schedules retention for delete-after-days and keeps the rule explanation" do
    winning_rule = rule("Delete after 30 days", "delete_after_days")

    result = described_class.call({ slide_uid: "IMP-RETENTION", case_id: "CASE-4", slide_type: "H&E" }, actor: user)

    expect(result.slide).to have_attributes(decision: "delete_after_retention", deletion_status: "scheduled", retention_status: "scheduled", retention_rule: winning_rule, retention_period: 30)
    expect(result.slide.retention_expires_at).to be_within(2.seconds).of(result.slide.received_at + 30.days)
  end

  it "rejects invalid slides before creating them" do
    expect do
      result = described_class.call({ slide_uid: "", case_id: "CASE-INVALID" }, actor: user)
      expect(result.errors[:slide_uid]).to be_present
    end.not_to change(Slide, :count)

    expect(AuditLog.where(event_type: "slide.import_rejected")).to exist
  end
end
