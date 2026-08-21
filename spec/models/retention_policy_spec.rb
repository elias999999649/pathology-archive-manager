require "rails_helper"

RSpec.describe RetentionPolicy, type: :model do
  it "supports all preset units" do
    expect(described_class.preset("30_days")).to be_valid
    expect(described_class.preset("6_months")).to be_valid
    expect(described_class.preset("1_year")).to be_valid
    expect(described_class.preset("forever")).to be_valid
  end

  it "rejects a forever policy with a value" do
    policy = described_class.new(code: "bad", name: "Bad", duration_unit: "forever", duration_value: 1)

    expect(policy).not_to be_valid
  end
end
