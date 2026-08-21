class ArchiveRule < ApplicationRecord
  FIELDS = %w[slide_type scanner hospital department stain diagnosis tags acquisition_date received_at file_size metadata].freeze
  OPERATORS = %w[equals not_equals contains not_contains starts_with ends_with greater_than less_than between is_present is_not_present].freeze
  ACTIONS = %w[keep delete manual_review keep_forever delete_after_days move_to_archive move_to_cold_storage add_tag send_notification].freeze
  DECISION_ACTIONS = %w[keep delete manual_review keep_forever delete_after_days].freeze

  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_many :rule_evaluations, foreign_key: :winning_rule_id, dependent: :restrict_with_exception

  scope :enabled_for_evaluation, -> { where(enabled: true).order(priority: :desc, id: :asc) }

  validates :name, presence: true
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :version, numericality: { only_integer: true, greater_than: 0 }
  validate :conditions_are_valid
  validate :actions_are_valid

  before_validation :stringify_definition_keys

  private

  def stringify_definition_keys
    self.conditions = conditions.deep_stringify_keys if conditions.respond_to?(:deep_stringify_keys)
    self.actions = actions.map { |action| action.respond_to?(:deep_stringify_keys) ? action.deep_stringify_keys : action } if actions.is_a?(Array)
  end

  def conditions_are_valid
    unless conditions.is_a?(Hash) && %w[and or].include?(conditions["logic"].to_s) && conditions["groups"].is_a?(Array) && conditions["groups"].present?
      errors.add(:conditions, "must contain a logic value and at least one condition group")
      return
    end

    conditions["groups"].each do |group|
      unless group.is_a?(Hash) && %w[and or].include?(group["logic"].to_s) && group["conditions"].is_a?(Array) && group["conditions"].present?
        errors.add(:conditions, "contains an invalid condition group")
        next
      end

      group["conditions"].each do |condition|
        unless condition.is_a?(Hash) && FIELDS.include?(condition["field"].to_s) && OPERATORS.include?(condition["operator"].to_s)
          errors.add(:conditions, "contains an invalid field or operator")
          next
        end

        if condition["field"].to_s == "metadata" && condition["path"].blank?
          errors.add(:conditions, "metadata conditions require a path")
        end

        if condition["operator"].to_s == "between" && (condition["value"].blank? || condition["value_to"].blank?)
          errors.add(:conditions, "between conditions require two values")
        end
      end
    end
  end

  def actions_are_valid
    unless actions.is_a?(Array) && actions.present?
      errors.add(:actions, "must contain at least one action")
      return
    end

    invalid_actions = actions.reject { |action| action.is_a?(Hash) && ACTIONS.include?(action["type"].to_s) }
    errors.add(:actions, "contains an unsupported action") if invalid_actions.present?

    decision_actions = actions.select { |action| action.is_a?(Hash) && DECISION_ACTIONS.include?(action["type"].to_s) }
    errors.add(:actions, "must contain exactly one decision action") unless decision_actions.one?

    actions.each do |action|
      next unless action.is_a?(Hash)

      if action["type"].to_s == "delete_after_days" && action["days"].to_i <= 0
        errors.add(:actions, "delete after days must be positive")
      end
      if action["type"].to_s == "add_tag" && action["tag"].to_s.strip.blank?
        errors.add(:actions, "add tag requires a tag")
      end
    end
  end
end
