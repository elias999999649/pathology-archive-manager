class AuditLog < ApplicationRecord
  EVENT_TYPES = %w[
    user.login api_connection.created api_connection.updated api_connection.deleted api_connection.toggled
    api_connection.test_succeeded api_connection.test_failed api_connection.sync_started api_connection.sync_succeeded api_connection.sync_failed
    slide.imported slide.import_rejected slide.automatic_decision slide.automatic_keep slide.automatic_delete
    slide.manual_review_decided slide.manual_keep slide.manual_delete
    archive_rule.created archive_rule.updated archive_rule.duplicated archive_rule.toggled archive_rule.enabled archive_rule.disabled archive_rule.deleted
    retention.changed retention.scheduled retention.expired slide.trashed storage.warning storage.checked storage.check_failed
    user.changed slide.permanently_deleted
  ].freeze

  belongs_to :actor, class_name: "User", optional: true

  validates :event_type, presence: true
  validate :metadata_is_an_object

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def readonly?
    persisted?
  end

  private

  def metadata_is_an_object
    errors.add(:metadata, "must be a JSON object") unless metadata.is_a?(Hash)
  end
end
