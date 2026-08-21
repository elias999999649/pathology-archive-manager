require "rails_helper"

RSpec.describe "Storage monitoring", type: :request do
  let(:admin) { User.create!(email: "storage-admin@example.com", password: "password12345", role: :archive_administrator) }
  let(:viewer) { User.create!(email: "storage-viewer@example.com", password: "password12345", role: :viewer) }

  it "shows storage settings to administrators" do
    sign_in admin
    StorageSnapshot.create!(provider_name: "Not configured", status: "unconfigured", checked_at: Time.current, slide_count: 0, by_slide_type: {}, by_hospital: {})

    get settings_storage_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Storage", "Not configured")
  end

  it "refreshes storage status" do
    sign_in admin

    expect { post settings_storage_refresh_path }.to change(StorageSnapshot, :count).by(1)
    expect(response).to redirect_to(settings_storage_path)
  end

  it "does not allow viewers to access storage settings" do
    sign_in viewer

    get settings_storage_path

    expect(response).to redirect_to(authenticated_root_path)
  end
end
