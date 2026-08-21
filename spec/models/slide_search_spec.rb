require "rails_helper"

RSpec.describe SlideSearch, type: :model do
  let!(:matching_slide) do
    Slide.create!(slide_uid: "UID-001", case_id: "CASE-001", patient_id: "PATIENT-001", scanner: "Aperio", hospital: "General", slide_type: "H&E", stain: "Hematoxylin", received_at: 2.days.ago, tags: ["urgent"])
  end
  let!(:other_slide) do
    Slide.create!(slide_uid: "UID-002", case_id: "CASE-002", patient_id: "PATIENT-002", scanner: "Hamamatsu", hospital: "Specialist", slide_type: "IHC", stain: "CD3", received_at: 1.day.ago)
  end

  it "searches across identifiers, descriptive fields, and tags" do
    expect(described_class.new(q: "urgent").call).to contain_exactly(matching_slide)
    expect(described_class.new(q: "PATIENT-001").call).to contain_exactly(matching_slide)
    expect(described_class.new(q: "Aperio").call).to contain_exactly(matching_slide)
  end

  it "supports explicit exact matching" do
    expect(described_class.new(q: "Aperio", match: "exact").call).to be_empty
    expect(described_class.new(q: "UID-001", match: "exact").call).to contain_exactly(matching_slide)
  end

  it "combines field filters server-side" do
    expect(described_class.new(hospital: "General", slide_type: "H&E").call).to contain_exactly(matching_slide)
  end

  it "filters by status and decision" do
    matching_slide.update!(status: "archived", decision: "keep")

    expect(described_class.new(status: "archived", decision: "keep").call).to contain_exactly(matching_slide)
    expect(described_class.new(status: "deleted").call).to be_empty
  end

  it "uses a safe allowlist for sorting" do
    expect(described_class.new(sort: "received_at", direction: "asc").call.to_a).to eq([matching_slide, other_slide])
    expect(described_class.new(sort: "not_a_column").call.to_a).to eq([other_slide, matching_slide])
  end

  it "ranks exact matches ahead of partial matches" do
    partial = Slide.create!(slide_uid: "UID-003", case_id: "CASE-003", scanner: "Aperio Compact", received_at: Time.current)

    expect(described_class.new(q: "Aperio").call.to_a.first).to eq(matching_slide)
    expect(partial).to be_present
  end

  it "supports acquisition and received date ranges without loading all rows" do
    matching_slide.update!(acquisition_date: Date.new(2026, 8, 10), received_at: Time.zone.parse("2026-08-10 12:00"))
    other_slide.update!(acquisition_date: Date.new(2026, 8, 20), received_at: Time.zone.parse("2026-08-20 12:00"))

    query = described_class.new(acquisition_from: "2026-08-01", acquisition_to: "2026-08-15", received_from: "2026-08-10", received_to: "2026-08-10")

    expect(query.call).to contain_exactly(matching_slide)
    expect(query.call).to be_a(ActiveRecord::Relation)
  end
end
