require "rails_helper"

RSpec.describe AuditLogSearch do
  let!(:user) { User.create!(email: "search-actor@example.com", password: "password12345") }
  let!(:matching) { AuditLog.create!(event_type: "slide.automatic_keep", actor: user, auditable_type: "Slide", auditable_id: SecureRandom.uuid, metadata: { "reason" => "Matched policy" }, created_at: Date.new(2026, 8, 10).midday) }
  let!(:other) { AuditLog.create!(event_type: "storage.checked", metadata: { "status" => "healthy" }, created_at: Date.new(2026, 8, 11).midday) }

  it "filters by user, event type, date, and metadata search" do
    results = described_class.new(user_id: user.id, event_type: "slide.automatic_keep", date: "2026-08-10", q: "Matched").call

    expect(results).to contain_exactly(matching)
    expect(results).not_to include(other)
  end
end
