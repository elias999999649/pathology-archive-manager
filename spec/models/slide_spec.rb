require "rails_helper"

RSpec.describe Slide, type: :model do
  subject(:slide) do
    described_class.new(
      slide_uid: "slide-001",
      case_id: "case-001",
      received_at: Time.current,
      metadata: { "source" => "lis" },
      tags: ["urgent"]
    )
  end

  it { is_expected.to be_valid }

  it "requires a unique slide UID" do
    described_class.create!(slide.attributes.except("id", "created_at", "updated_at"))

    expect(slide).not_to be_valid
    expect(slide.errors[:slide_uid]).to include("has already been taken")
  end

  it "rejects a deleted slide without a delete decision" do
    slide.status = :deleted
    slide.decision = :keep

    expect(slide).not_to be_valid
    expect(slide.errors[:decision]).to include("must be delete when the slide is deleted")
  end

  it "rejects an under-review slide with a keep decision" do
    slide.status = :under_review
    slide.decision = :keep

    expect(slide).not_to be_valid
  end

  it "requires an archive-compatible decision for archived slides" do
    slide.status = :archived
    slide.decision = :undecided

    expect(slide).not_to be_valid
  end

  it "requires a retention period for delete-after-retention" do
    slide.decision = :delete_after_retention

    expect(slide).not_to be_valid
    expect(slide.errors[:retention_period]).to include("or a retention duration is required for delete after retention")
  end

  it "does not allow an expiration date for keep forever" do
    slide.decision = :keep_forever
    slide.retention_expires_at = 1.year.from_now

    expect(slide).not_to be_valid
  end

  it "requires metadata to be a JSON object and tags to be strings" do
    slide.metadata = ["not", "an", "object"]
    slide.tags = ["valid", 123]

    expect(slide).not_to be_valid
    expect(slide.errors[:metadata]).to include("must be a JSON object")
    expect(slide.errors[:tags]).to include("must contain only strings")
  end

  it "belongs to an optional source API connection" do
    connection = ApiConnection.new(name: "Pathology API")
    slide.source_api_connection = connection

    expect(slide.source_api_connection).to eq(connection)
  end
end
