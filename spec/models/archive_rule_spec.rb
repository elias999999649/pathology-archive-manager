require "rails_helper"

RSpec.describe ArchiveRule, type: :model do
  let(:user) { User.create!(email: "admin@example.com", password: "password12345", role: :archive_administrator) }
  let(:conditions) { { "logic" => "and", "groups" => [{ "logic" => "and", "conditions" => [{ "field" => "slide_type", "operator" => "equals", "value" => "H&E" }] }] } }
  let(:actions) { [{ "type" => "keep" }] }

  it "accepts a valid rule definition" do
    rule = described_class.new(name: "Keep H&E", priority: 10, conditions: conditions, actions: actions, created_by: user, updated_by: user)

    expect(rule).to be_valid
  end

  it "requires exactly one decision action" do
    rule = described_class.new(name: "Conflicting", priority: 10, conditions: conditions, actions: [{ "type" => "keep" }, { "type" => "delete" }], created_by: user, updated_by: user)

    expect(rule).not_to be_valid
    expect(rule.errors[:actions]).to include("must contain exactly one decision action")
  end

  it "rejects unsupported operators and incomplete between conditions" do
    rule = described_class.new(name: "Invalid", priority: 10, conditions: { "logic" => "and", "groups" => [{ "logic" => "and", "conditions" => [{ "field" => "slide_type", "operator" => "unknown", "value" => "H&E" }, { "field" => "slide_type", "operator" => "between", "value" => "H&E" }] }] }, actions: actions, created_by: user, updated_by: user)

    expect(rule).not_to be_valid
    expect(rule.errors[:conditions].join).to include("invalid field or operator")
  end
end
