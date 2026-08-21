class Slide < ApplicationRecord
  SEARCHABLE_FIELDS = %w[slide_uid case_id patient_id barcode scanner hospital department slide_type stain].freeze

  belongs_to :source_api_connection, class_name: "ApiConnection", optional: true, inverse_of: :slides
  belongs_to :retention_policy, optional: true
  belongs_to :retention_rule, class_name: "ArchiveRule", optional: true
  has_many :rule_evaluations, dependent: :restrict_with_exception
  has_many :reviews, dependent: :restrict_with_exception

  enum :status, {
    received: "received",
    available: "available",
    under_review: "under_review",
    archived: "archived",
    deleted: "deleted"
  }, validate: true

  enum :decision, {
    undecided: "undecided",
    keep: "keep",
    delete: "delete",
    manual_review: "manual_review",
    keep_forever: "keep_forever",
    delete_after_retention: "delete_after_retention"
  }, validate: true

  enum :retention_status, {
    not_scheduled: "not_scheduled",
    scheduled: "scheduled",
    forever: "forever",
    eligible_for_deletion: "eligible_for_deletion"
  }, validate: true

  enum :deletion_status, {
    none: "none",
    scheduled: "scheduled",
    eligible_for_trash: "eligible_for_trash",
    trashed: "trashed",
    permanently_deleted: "permanently_deleted"
  }, prefix: true, validate: true

  validates :slide_uid, :case_id, :received_at, presence: true
  validates :slide_uid, uniqueness: true
  validates :file_size, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :retention_period, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :metadata_is_an_object
  validate :tags_are_strings
  validate :status_and_decision_are_consistent
  validate :retention_requirements

  before_validation :normalize_identifiers

  scope :newest_first, -> { order(received_at: :desc, id: :desc) }
  scope :scheduled_for_retention, -> { where(retention_status: "scheduled") }
  scope :eligible_for_deletion, -> { where(retention_status: "eligible_for_deletion") }
  scope :expiring_soon, ->(until_time = 30.days.from_now) { scheduled_for_retention.where(retention_expires_at: Time.current..until_time) }
  scope :deletion_queue, -> { where(deletion_status: %w[scheduled eligible_for_trash trashed]) }
  scope :review_queue, -> { where(status: "under_review") }

  def latest_rule_evaluation
    rule_evaluations.order(evaluated_at: :desc).first
  end

  private

  def normalize_identifiers
    self.slide_uid = slide_uid.to_s.strip if slide_uid
    self.case_id = case_id.to_s.strip if case_id
    self.barcode = barcode.to_s.strip if barcode
  end

  def metadata_is_an_object
    errors.add(:metadata, "must be a JSON object") unless metadata.is_a?(Hash)
  end

  def tags_are_strings
    errors.add(:tags, "must contain only strings") unless tags.is_a?(Array) && tags.all? { |tag| tag.is_a?(String) }
  end

  def status_and_decision_are_consistent
    if deleted? && !delete?
      errors.add(:decision, "must be delete when the slide is deleted")
    end

    if delete? && !received? && !available? && !deleted?
      errors.add(:status, "must be received, available, or deleted for a delete decision")
    end

    if under_review? && !undecided? && !manual_review?
      errors.add(:decision, "must be undecided or manual review while under review")
    end

    if archived? && !keep? && !keep_forever? && !delete_after_retention?
      errors.add(:decision, "must be a keep decision when archived")
    end

    if manual_review? && !received? && !available? && !under_review?
      errors.add(:status, "must be received, available, or under review for manual review")
    end
  end

  def retention_requirements
    if delete_after_retention? && retention_period.blank? && retention_duration.blank?
      errors.add(:retention_period, "or a retention duration is required for delete after retention")
    end

    if keep_forever? && retention_expires_at.present?
      errors.add(:retention_expires_at, "must be blank for keep forever")
    end
  end
end
