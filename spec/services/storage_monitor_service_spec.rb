require "rails_helper"

RSpec.describe StorageMonitorService do
  around do |example|
    original = ENV["STORAGE_TOTAL_BYTES"]
    ENV["STORAGE_TOTAL_BYTES"] = "1000"
    example.run
    ENV["STORAGE_TOTAL_BYTES"] = original
  end

  it "calculates capacity, thresholds, and breakdowns" do
    Slide.create!(slide_uid: "STORE-1", case_id: "CASE-1", slide_type: "H&E", hospital: "General", file_size: 950, received_at: Time.current)

    snapshot = described_class.refresh!

    expect(snapshot).to have_attributes(provider_name: "Not configured", total_bytes: 1000, used_bytes: 950, free_bytes: 50, usage_percentage: 95.0, status: "critical_95", slide_count: 1)
    expect(snapshot.by_slide_type).to eq("H&E" => 950)
    expect(snapshot.by_hospital).to eq("General" => 950)
  end

  it "calculates growth and remaining capacity from the previous snapshot" do
    first_time = Time.zone.parse("2026-08-20 00:00")
    described_class.refresh!(checked_at: first_time)
    Slide.create!(slide_uid: "STORE-2", case_id: "CASE-2", file_size: 100, received_at: first_time)

    snapshot = described_class.refresh!(checked_at: first_time + 2.days)

    expect(snapshot.growth_bytes_per_day).to eq(50)
    expect(snapshot.estimated_remaining_days).to eq(18)
  end

  it "returns unconfigured status when capacity is unavailable" do
    ENV.delete("STORAGE_TOTAL_BYTES")

    expect(described_class.refresh!.status).to eq("unconfigured")
  end
end
