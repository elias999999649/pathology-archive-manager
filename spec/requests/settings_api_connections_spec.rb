require "rails_helper"

RSpec.describe "Settings API Connections", type: :request do
  let(:admin) { User.create!(email: "admin@example.com", password: "password12345", role: :archive_administrator) }
  let(:viewer) { User.create!(email: "viewer@example.com", password: "password12345", role: :viewer) }

  it "allows administrators to create a connection without echoing credentials" do
    sign_in admin

    post settings_api_connections_path, params: { api_connection: { name: "Generic", base_url: "https://example.test", authentication_method: "bearer_token", credentials_token: "top-secret", sync_interval: 60, enabled: "1" } }

    expect(response).to redirect_to(settings_api_connections_path)
    expect(ApiConnection.last.credentials).to eq("token" => "top-secret")
    expect(response.body).not_to include("top-secret")
  end

  it "does not allow viewers to access connections" do
    sign_in viewer

    get settings_api_connections_path

    expect(response).to redirect_to(authenticated_root_path)
  end

  it "queues a manual synchronization" do
    sign_in admin
    connection = ApiConnection.create!(name: "Generic", base_url: "https://example.test", sync_interval: 60)

    expect { post sync_settings_api_connection_path(connection) }.to have_enqueued_job(ApiConnectionSyncJob).with(connection.id)
  end

  it "keeps enabled state and status aligned when toggled" do
    sign_in admin
    connection = ApiConnection.create!(name: "Generic", base_url: "https://example.test", sync_interval: 60)

    patch toggle_settings_api_connection_path(connection)

    expect(connection.reload).to have_attributes(enabled: false, status: "disabled")
  end
end
