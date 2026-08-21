require "rails_helper"

RSpec.describe Storage::Provider do
  it "defines a provider contract without selecting a cloud vendor" do
    expect { described_class.new.summary(slides: []) }.to raise_error(NotImplementedError)
  end

  it "has a safe null provider" do
    expect(Storage::Registry.build).to be_a(Storage::NullProvider)
  end
end
