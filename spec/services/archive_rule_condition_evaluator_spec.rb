require "rails_helper"

RSpec.describe ArchiveRuleConditionEvaluator do
  let(:slide) do
    Slide.new(slide_uid: "UID-1", case_id: "CASE-1", slide_type: "H&E", scanner: "Aperio", hospital: "General Hospital", department: "Histology", stain: "Hematoxylin", diagnosis: "Benign lesion", acquisition_date: Date.new(2026, 1, 10), received_at: Time.zone.parse("2026-01-11 12:00"), file_size: 500, metadata: { "specimen" => { "body_site" => "lung" } }, tags: ["urgent", "research"])
  end

  { "equals" => "H&E", "not_equals" => "IHC", "contains" => "ospital", "not_contains" => "malignant", "starts_with" => "Gen", "ends_with" => "Hospital", "greater_than" => "400", "less_than" => "600", "between" => ["400", "600"] }.each do |operator, value|
    it "supports #{operator}" do
      condition = { "field" => operator == "greater_than" || operator == "less_than" || operator == "between" ? "file_size" : "hospital", "operator" => operator, "value" => operator == "between" ? value.first : value, "value_to" => operator == "between" ? value.last : nil }

      expect(described_class.call(slide, condition)[:matched]).to be(true)
    end
  end

  it "supports tags, metadata, and presence operators" do
    expect(described_class.call(slide, field: "tags", operator: "equals", value: "urgent")[:matched]).to be(true)
    expect(described_class.call(slide, field: "metadata", path: "specimen.body_site", operator: "equals", value: "lung")[:matched]).to be(true)
    expect(described_class.call(slide, field: "diagnosis", operator: "is_present")[:matched]).to be(true)
    expect(described_class.call(slide, field: "diagnosis", operator: "is_not_present")[:matched]).to be(false)
  end
end
