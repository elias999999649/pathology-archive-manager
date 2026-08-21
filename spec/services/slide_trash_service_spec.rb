require "rails_helper"

RSpec.describe SlideTrashService do
  let!(:slide) { Slide.create!(slide_uid: "TRASH-1", case_id: "CASE-1", received_at: Time.current, deletion_status: "eligible_for_trash", retention_status: "eligible_for_deletion") }

  it "soft-trashes an eligible slide without permanent deletion" do
    described_class.call(slide)

    expect(slide.reload).to have_attributes(deletion_status: "trashed")
    expect(slide.trashed_at).to be_present
    expect(Slide.exists?(slide.id)).to be(true)
  end

  it "rejects slides that are not eligible" do
    slide.update!(deletion_status: "scheduled")

    expect { described_class.call(slide) }.to raise_error(ArgumentError, "Slide is not eligible for trash")
  end
end
