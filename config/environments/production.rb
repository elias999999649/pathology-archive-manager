require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.active_storage.service = :local
  config.action_mailer.raise_delivery_errors = true
  config.active_support.deprecation = :notify
end
