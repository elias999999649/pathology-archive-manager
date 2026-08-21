require "rails_helper"

RSpec.describe DashboardStatsService do
  let(:payload) do
    {
      slides: { total: 3 }, storage: {}, api: { connected: 0 },
      rules: { active: 1, recent_decisions: [], distribution: {} },
      activity: [], retention: { expiring_soon: 0, eligible_for_deletion: 0 }
    }
  end

  before { described_class.clear! }

  it "caches the computed dashboard payload briefly" do
    service = instance_double(described_class, build: payload)
    allow(described_class).to receive(:new).and_return(service)

    expect(described_class.call).to eq(payload)
    expect(described_class.call).to eq(payload)
    expect(service).to have_received(:build).once
  end

  it "clears the cached payload" do
    service = instance_double(described_class, build: payload)
    allow(described_class).to receive(:new).and_return(service)

    described_class.call
    described_class.clear!
    described_class.call

    expect(service).to have_received(:build).twice
  end
end
