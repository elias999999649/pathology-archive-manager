require "rails_helper"

RSpec.describe "Retention queue", type: :request do
  let(:admin) { User.create!(email: "retention-admin@example.com", password: "password12345", role: :archive_administrator) }
  let(:viewer) { User.create!(email: "retention-viewer@example.com", password: "password12345", role: :viewer) }

  it "shows expiring and deletion-eligible slides to administrators" do
    sign_in admin
    Slide.create!(slide_uid: "RET-SOON", case_id: "CASE-1", received_at: Time.current, retention_expires_at: 2.days.from_now, retention_status: "scheduled", retention_duration: { "unit" => "days", "value" => 2 })
    Slide.create!(slide_uid: "RET-QUEUE", case_id: "CASE-2", received_at: Time.current, retention_expires_at: 1.day.ago, retention_status: "eligible_for_deletion", retention_duration: { "unit" => "days", "value" => 1 })

    get retention_queue_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("RET-SOON", "RET-QUEUE", "Deletion queue")
  end

  it "protects the queue from viewers" do
    sign_in viewer

    get retention_queue_path

    expect(response).to redirect_to(authenticated_root_path)
  end
end
