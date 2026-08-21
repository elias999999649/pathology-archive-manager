require "rails_helper"

RSpec.describe StorageSnapshot, type: :model do
  subject(:snapshot) { described_class.new(provider_name: "Test provider", status: "warning_90", checked_at: Time.current, usage_percentage: 92.5, slide_count: 12, by_slide_type: {}, by_hospital: {}) }

  it { is_expected.to be_valid }
  it { is_expected.to be_warning }

  it "identifies critical capacity" do
    snapshot.status = "critical_95"

    expect(snapshot).to be_critical
  end

  it "rejects percentages outside the valid range" do
    snapshot.usage_percentage = 101

    expect(snapshot).not_to be_valid
  end
end
