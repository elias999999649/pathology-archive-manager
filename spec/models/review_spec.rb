require "rails_helper"

RSpec.describe Review, type: :model do
  let(:user) { User.create!(email: "reviewer@example.com", password: "password12345", role: :reviewer) }
  let(:slide) { Slide.create!(slide_uid: "REV-1", case_id: "CASE-1", received_at: Time.current, status: "under_review", decision: "manual_review") }

  it "stores the reviewer decision and previous state" do
    review = described_class.new(slide: slide, reviewer: user, decision: "keep", previous_state: { "status" => "under_review" }, decided_at: Time.current)

    expect(review).to be_valid
  end

  it "rejects unsupported decisions" do
    review = described_class.new(slide: slide, reviewer: user, decision: "manual_review", previous_state: {}, decided_at: Time.current)

    expect(review).not_to be_valid
  end
end
