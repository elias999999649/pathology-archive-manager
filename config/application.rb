require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module PathologyArchiveManager
  class Application < Rails::Application
    config.load_defaults 8.0
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc
    config.active_job.queue_adapter = :sidekiq
    config.filter_parameters += [:password, :token, :credentials_token, :credentials, :authorization, :api_key, :secret]
    if ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].present?
      config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY")
      config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY")
      config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
    elsif Rails.env.production?
      raise "Active Record encryption keys must be configured in production"
    else
      config.active_record.encryption.primary_key = "pam-development-primary-key-0000"
      config.active_record.encryption.deterministic_key = "pam-development-deterministic-00"
      config.active_record.encryption.key_derivation_salt = "pam-development-derivation-00000"
    end
    config.autoload_lib(ignore: %w[assets tasks])

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.test_framework :rspec, fixture: false
      g.stylesheets false
      g.javascripts false
      g.helper false
    end
  end
end
