class ArchiveRulesController < ApplicationController
  before_action :set_rule, except: [:index, :new, :create, :validate]

  def index
    authorize ArchiveRule
    @rules = ArchiveRule.includes(:created_by, :updated_by).order(priority: :desc, id: :asc)
  end

  def validate
    @rule = ArchiveRule.new(rule_params.merge(created_by: current_user, updated_by: current_user, version: 1))
    authorize @rule, :create?
    @validation_message = @rule.valid? ? "This rule is valid and ready to save." : "Please correct the validation errors below."
    render :new, status: @rule.errors.any? ? :unprocessable_entity : :ok
  end

  def new
    @rule = ArchiveRule.new(
      priority: 0,
      conditions: { "logic" => "and", "groups" => [{ "logic" => "and", "conditions" => [{ "field" => "slide_type", "operator" => "equals", "value" => "" }] }] },
      actions: [{ "type" => "keep" }]
    )
    authorize @rule
  end

  def create
    @rule = ArchiveRule.new(rule_params.merge(created_by: current_user, updated_by: current_user, version: 1))
    authorize @rule
    if @rule.save
      AuditLogger.record!(event_type: "archive_rule.created", auditable: @rule, actor: current_user, metadata: { version: @rule.version })
      redirect_to settings_archive_rules_path, notice: "Archive rule created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @rule
  end

  def update
    authorize @rule
    if @rule.update(rule_params.merge(updated_by: current_user, version: @rule.version + 1))
      AuditLogger.record!(event_type: "archive_rule.updated", auditable: @rule, actor: current_user, metadata: { version: @rule.version })
      redirect_to settings_archive_rules_path, notice: "Archive rule updated to version #{@rule.version}."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @rule
    @rule.destroy!
    AuditLogger.record!(event_type: "archive_rule.deleted", auditable: @rule, actor: current_user)
    redirect_to settings_archive_rules_path, notice: "Archive rule deleted."
  end

  def duplicate
    authorize @rule, :create?
    duplicate = @rule.dup
    duplicate.name = "#{@rule.name} (Copy)"
    duplicate.enabled = false
    duplicate.version = 1
    duplicate.created_by = current_user
    duplicate.updated_by = current_user
    duplicate.save!
    AuditLogger.record!(event_type: "archive_rule.duplicated", auditable: duplicate, actor: current_user, metadata: { source_rule_id: @rule.id })
    redirect_to edit_settings_archive_rule_path(duplicate), notice: "Rule duplicated. Review it before enabling."
  end

  private

  def set_rule
    @rule = ArchiveRule.find(params[:id])
  end

  def rule_params
    raw = params.require(:archive_rule)
    permitted = raw.permit(:name, :description, :priority, :enabled)
    permitted[:conditions] = normalize_conditions(raw[:conditions])
    permitted[:actions] = normalize_actions(raw[:actions])
    permitted
  end

  def normalize_conditions(raw)
    raw = raw.to_h.stringify_keys
    groups = raw.fetch("groups", {}).to_h.values.map do |group|
      group = group.to_h.stringify_keys
      condition_values = group.fetch("conditions", {}).to_h.values.map { |condition| condition.to_h.stringify_keys.slice("field", "operator", "value", "value_to", "path") }
      { "logic" => group["logic"], "conditions" => condition_values }
    end
    { "logic" => raw["logic"], "groups" => groups }
  end

  def normalize_actions(raw)
    raw.to_h.stringify_keys.values.map { |action| action.to_h.stringify_keys.slice("type", "days", "tag", "channel") }
  end
end
