require "rails_helper"

RSpec.describe ReviewDecisionService do
  let!(:reviewer) { User.create!(email: "reviewer-service@example.com", password: "password12345", role: :reviewer) }
  let!(:slide) { Slide.create!(slide_uid: "REV-SVC", case_id: "CASE-SVC", received_at: Time.current, status: "under_review", decision: "manual_review", tags: ["existing"]) }

  it "records a keep decision with comment, tags, retention, and previous state" do
    result = described_class.call(slide, reviewer: reviewer, decision: "keep", comment: "Confirmed benign.", retention_policy_code: "1_year", tags: "reviewed,confirmed")

    expect(result.slide.reload).to have_attributes(status: "available", decision: "keep", tags: ["existing", "reviewed", "confirmed"], retention_status: "scheduled")
    expect(result.review).to have_attributes(reviewer: reviewer, decision: "keep", comment: "Confirmed benign.", tags_added: ["reviewed", "confirmed"])
    expect(result.review.previous_state["status"]).to eq("under_review")
    expect(AuditLog.where(event_type: "slide.manual_review_decided", auditable_id: result.review.id)).to exist
  end

  it "schedules a manual delete without permanently deleting" do
    result = described_class.call(slide, reviewer: reviewer, decision: "delete", comment: "No diagnostic value.")

    expect(result.slide.reload).to have_attributes(status: "available", decision: "delete", deletion_status: "scheduled")
    expect(Slide.exists?(result.slide.id)).to be(true)
  end
end
