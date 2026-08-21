require "rails_helper"

RSpec.describe "Audit logs", type: :request do
  let(:admin) { User.create!(email: "audit-admin@example.com", password: "password12345", role: :archive_administrator) }
  let(:viewer) { User.create!(email: "audit-viewer@example.com", password: "password12345", role: :viewer) }

  it "shows filtered audit events to administrators" do
    sign_in admin
    AuditLog.create!(event_type: "slide.automatic_keep", actor: admin, metadata: { "reason" => "Policy match" })

    get audit_logs_path, params: { event_type: "slide.automatic_keep", q: "Policy match" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Slide automatic keep", "Policy match")
  end

  it "keeps audit logs read-only and restricts them to administrators" do
    sign_in viewer

    get audit_logs_path

    expect(response).to redirect_to(authenticated_root_path)
  end
end
