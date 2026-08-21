require "rails_helper"

RSpec.describe AuditLogger do
  it "redacts secret-shaped metadata" do
    log = AuditLog.new(event_type: "test", metadata: described_class.send(:redact, { token: "secret", nested: { password: "hidden" }, count: 2 }))

    expect(log.metadata).to eq("token" => "[REDACTED]", "nested" => { "password" => "[REDACTED]" }, "count" => 2)
  end

  it "stores explainable change details without secrets" do
    actor = User.create!(email: "audit-actor@example.com", password: "password12345")

    log = described_class.record!(event_type: "retention.changed", actor: actor, reason: "Policy selected by reviewer", previous_value: { retention: "30 days" }, new_value: { retention: "1 year", token: "hidden" })

    expect(log.metadata).to include("reason" => "Policy selected by reviewer", "previous_value" => { "retention" => "30 days" })
    expect(log.metadata.dig("new_value", "token")).to eq("[REDACTED]")
  end

  it "does not allow persisted audit records to be edited" do
    log = AuditLog.create!(event_type: "test", metadata: {})

    expect(log).to be_readonly
    expect { log.update!(event_type: "changed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
