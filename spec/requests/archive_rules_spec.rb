require "rails_helper"

RSpec.describe "Archive rules", type: :request do
  let(:admin) { User.create!(email: "rule-admin@example.com", password: "password12345", role: :archive_administrator) }
  let(:viewer) { User.create!(email: "rule-viewer@example.com", password: "password12345", role: :viewer) }
  let(:reviewer) { User.create!(email: "rule-reviewer@example.com", password: "password12345", role: :reviewer) }
  let(:rule_params) do
    {
      name: "Keep H&E",
      description: "Keep H&E slides",
      priority: 10,
      enabled: "1",
      conditions: {
        logic: "and",
        groups: { "0" => { logic: "and", conditions: { "0" => { field: "slide_type", operator: "equals", value: "H&E" } } } }
      },
      actions: { "0" => { type: "keep" } }
    }
  end

  it "allows administrators to create rules from form values" do
    sign_in admin

    post settings_archive_rules_path, params: { archive_rule: rule_params }

    expect(response).to redirect_to(settings_archive_rules_path)
    expect(ArchiveRule.last).to have_attributes(name: "Keep H&E", version: 1, created_by: admin, updated_by: admin)
  end

  it "increments rule version when an administrator edits it" do
    sign_in admin
    rule = ArchiveRule.create!(name: "Keep H&E", priority: 10, conditions: { "logic" => "and", "groups" => [{ "logic" => "and", "conditions" => [{ "field" => "slide_type", "operator" => "equals", "value" => "H&E" }] }] }, actions: [{ "type" => "keep" }], created_by: admin, updated_by: admin)

    patch settings_archive_rule_path(rule), params: { archive_rule: rule_params }

    expect(response).to redirect_to(settings_archive_rules_path)
    expect(rule.reload.version).to eq(2)
  end

  it "does not allow viewers to access rules" do
    sign_in viewer

    get settings_archive_rules_path

    expect(response).to redirect_to(authenticated_root_path)
  end

  it "does not allow reviewers to access administrator settings" do
    sign_in reviewer

    get settings_archive_rules_path

    expect(response).to redirect_to(authenticated_root_path)
  end

  it "validates a rule without saving it" do
    sign_in admin

    expect do
      post validate_settings_archive_rules_path, params: { archive_rule: rule_params }
    end.not_to change(ArchiveRule, :count)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("This rule is valid and ready to save.")
  end

  it "duplicates a rule as disabled version one" do
    sign_in admin
    rule = ArchiveRule.create!(name: "Keep H&E", priority: 10, enabled: true, conditions: { "logic" => "and", "groups" => [{ "logic" => "and", "conditions" => [{ "field" => "slide_type", "operator" => "equals", "value" => "H&E" }] }] }, actions: [{ "type" => "keep" }], created_by: admin, updated_by: admin)

    expect { post duplicate_settings_archive_rule_path(rule) }.to change(ArchiveRule, :count).by(1)

    copy = ArchiveRule.order(:created_at).last
    expect(copy).to have_attributes(name: "Keep H&E (Copy)", enabled: false, version: 1, created_by: admin)
  end
end
