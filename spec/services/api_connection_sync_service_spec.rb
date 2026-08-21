require "rails_helper"

RSpec.describe ApiConnectionSyncService do
  let(:connection) { ApiConnection.create!(name: "Generic API", base_url: "https://example.test", enabled: true, sync_interval: 60) }

  it "records a successful generic synchronization without inventing a payload format" do
    result = described_class.call(connection)

    expect(result).to be_success
    expect(result.imported_count).to eq(0)
    expect(connection.reload).to have_attributes(status: "healthy", last_error: nil)
    expect(AuditLog.where(event_type: "api_connection.sync_succeeded")).to exist
  end

  it "does not synchronize disabled connections" do
    connection.update!(enabled: false, status: "disabled")

    result = described_class.call(connection)

    expect(result).not_to be_success
    expect(result.message).to eq("Connection is disabled.")
  end

  it "redacts configured credentials from provider errors" do
    connection.credentials = { "token" => "super-secret-token" }
    error = StandardError.new("Authorization: Bearer super-secret-token")

    safe = described_class.safe_error_message(error, connection: connection)

    expect(safe).not_to include("super-secret-token")
    expect(safe).to include("[REDACTED]")
  end
end
