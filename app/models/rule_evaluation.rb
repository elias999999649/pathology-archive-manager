class RuleEvaluation < ApplicationRecord
  belongs_to :slide
  belongs_to :winning_rule, class_name: "ArchiveRule", optional: true

  validates :final_decision, inclusion: { in: Slide.decisions.keys.map(&:to_s) }
  validates :reason, :evaluated_at, presence: true
  validate :details_are_an_object

  private

  def details_are_an_object
    errors.add(:details, "must be a JSON object") unless details.is_a?(Hash)
  end
end
