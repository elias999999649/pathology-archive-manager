require "uri"

class ApiConnection < ApplicationRecord
  AUTHENTICATION_METHODS = %w[none api_key bearer_token basic_auth].freeze
  STATUSES = %w[unknown testing syncing healthy error disabled].freeze

  attr_accessor :credentials_token

  has_many :slides, foreign_key: :source_api_connection_id, inverse_of: :source_api_connection, dependent: :restrict_with_exception

  serialize :credentials, coder: JSON, type: Hash
  encrypts :credentials

  validates :name, :base_url, presence: true, uniqueness: { case_sensitive: false }
  validates :authentication_method, inclusion: { in: AUTHENTICATION_METHODS }
  validates :status, inclusion: { in: STATUSES }
  validates :sync_interval, numericality: { only_integer: true, greater_than: 0 }
  validate :base_url_is_http

  def credentials_configured?
    credentials.present? && credentials.values.any?(&:present?)
  end

  def authentication_label
    authentication_method.humanize
  end

  private

  def base_url_is_http
    uri = URI.parse(base_url.to_s)
    errors.add(:base_url, "must use HTTP or HTTPS") unless uri.is_a?(URI::HTTP) && uri.host.present?
    errors.add(:base_url, "must not contain embedded credentials") if uri.userinfo.present?
  rescue URI::InvalidURIError
    errors.add(:base_url, "is not a valid URL")
  end
end
