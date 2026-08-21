require "rails_helper"

RSpec.describe RetentionCalculator do
  it "adds days exactly" do
    started_at = Time.zone.parse("2026-01-15 10:30")
    result = described_class.call(RetentionPolicy.preset("30_days"), started_at: started_at)

    expect(result.expires_at).to eq(Time.zone.parse("2026-02-14 10:30"))
  end

  it "uses calendar-aware month arithmetic at month end" do
    started_at = Time.zone.parse("2026-01-31 10:30")
    result = described_class.call(RetentionPolicy.preset("6_months"), started_at: started_at)

    expect(result.expires_at).to eq(Time.zone.parse("2026-07-31 10:30"))
  end

  it "handles leap years when adding years" do
    started_at = Time.zone.parse("2024-02-29 10:30")
    result = described_class.call(RetentionPolicy.preset("1_year"), started_at: started_at)

    expect(result.expires_at).to eq(Time.zone.parse("2025-02-28 10:30"))
  end

  it "supports custom durations" do
    policy = RetentionPolicy.new(code: "custom", name: "Custom", duration_unit: "days", duration_value: 45)

    expect(described_class.call(policy, started_at: Time.zone.parse("2026-01-01"))).to have_attributes(expires_at: Time.zone.parse("2026-02-15"))
  end

  it "returns no expiration for forever" do
    expect(described_class.call(RetentionPolicy.preset("forever"), started_at: Time.current).expires_at).to be_nil
  end
end
