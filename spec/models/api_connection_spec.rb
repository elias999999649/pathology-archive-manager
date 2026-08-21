require "rails_helper"

RSpec.describe ApiConnection, type: :model do
  subject(:connection) { described_class.new(name: "Pathology API", base_url: "https://example.test", sync_interval: 60) }

  it { is_expected.to be_valid }

  it "encrypts credentials and exposes only a configured state" do
    connection.credentials = { "token" => "super-secret" }
    connection.save!

    expect(connection.credentials_configured?).to be(true)
    expect(connection.credentials).to eq("token" => "super-secret")
    expect(connection.attributes_before_type_cast["credentials"]).not_to include("super-secret")
  end

  it "rejects credentials embedded in the base URL" do
    connection = described_class.new(name: "Unsafe URL", base_url: "https://user:password@example.com", authentication_method: "none", sync_interval: 60)

    expect(connection).not_to be_valid
    expect(connection.errors[:base_url]).to include("must not contain embedded credentials")
  end

  it "rejects non-http URLs" do
    connection.base_url = "ftp://example.test"

    expect(connection).not_to be_valid
  end

  it "requires a positive sync interval" do
    connection.sync_interval = 0

    expect(connection).not_to be_valid
  end
end
