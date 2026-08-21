require "rails_helper"

RSpec.describe "Reviews", type: :request do
  let(:reviewer) { User.create!(email: "queue-reviewer@example.com", password: "password12345", role: :reviewer) }
  let(:viewer) { User.create!(email: "queue-viewer@example.com", password: "password12345", role: :viewer) }
  let!(:slide) { Slide.create!(slide_uid: "REV-QUEUE", case_id: "CASE-QUEUE", slide_type: "H&E", status: "under_review", decision: "manual_review", received_at: Time.current, metadata: { "reason" => "ambiguous" }) }

  it "shows the review queue and slide details to reviewers" do
    sign_in reviewer

    get reviews_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("REV-QUEUE")

    get review_path(slide)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Why review is needed", "External metadata")
  end

  it "allows a reviewer to submit a keep decision" do
    sign_in reviewer

    post decide_review_path(slide), params: { decision: "keep", comment: "Reviewed", tags: "confirmed", retention_policy_code: "none" }

    expect(response).to redirect_to(reviews_path)
    expect(slide.reload).to have_attributes(status: "available", decision: "keep")
  end

  it "requires reviewer authorization" do
    sign_in viewer

    get reviews_path

    expect(response).to redirect_to(authenticated_root_path)
  end

  it "does not let viewers modify a slide through the review endpoint" do
    sign_in viewer

    post decide_review_path(slide), params: { decision: "delete", comment: "Unauthorized" }

    expect(response).to redirect_to(authenticated_root_path)
    expect(slide.reload.decision).to eq("manual_review")
  end

  it "does not let a reviewer decide a slide outside the review queue" do
    other_slide = Slide.create!(slide_uid: "AVAILABLE-QUEUE", case_id: "CASE-AVAILABLE", status: "available", decision: "keep", received_at: Time.current)
    sign_in reviewer

    post decide_review_path(other_slide), params: { decision: "delete", comment: "Should not be accepted" }

    expect(response).to redirect_to(authenticated_root_path)
    expect(other_slide.reload.decision).to eq("keep")
  end
end
