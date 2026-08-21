require "rails_helper"

RSpec.describe RetentionExpirationService do
  let!(:expired) { Slide.create!(slide_uid: "RET-EXPIRED", case_id: "CASE-1", received_at: 10.days.ago, retention_started_at: 10.days.ago, retention_expires_at: 1.day.ago, retention_status: "scheduled", deletion_status: "scheduled", retention_duration: { "unit" => "days", "value" => 9 }) }
  let!(:future) { Slide.create!(slide_uid: "RET-FUTURE", case_id: "CASE-2", received_at: Time.current, retention_started_at: Time.current, retention_expires_at: 1.day.from_now, retention_status: "scheduled", retention_duration: { "unit" => "days", "value" => 1 }) }

  it "marks expired slides eligible without deleting them" do
    expect { described_class.call(as_of: Time.current) }.to change { expired.reload.retention_status }.from("scheduled").to("eligible_for_deletion")

    expect(Slide.exists?(expired.id)).to be(true)
    expect(expired.reload.deletion_status).to eq("eligible_for_trash")
    expect(future.reload.retention_status).to eq("scheduled")
    expect(AuditLog.where(event_type: "retention.expired", auditable_id: expired.id)).to exist
  end

  it "treats an expiration exactly at the cutoff as expired" do
    boundary = Time.zone.parse("2026-08-21 12:00")
    slide = Slide.create!(slide_uid: "RET-BOUNDARY", case_id: "CASE-3", received_at: boundary - 1.day, retention_started_at: boundary - 1.day, retention_expires_at: boundary, retention_status: "scheduled", retention_duration: { "unit" => "days", "value" => 1 })

    described_class.call(as_of: boundary)

    expect(slide.reload.retention_status).to eq("eligible_for_deletion")
  end
end
