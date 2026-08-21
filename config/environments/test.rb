require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :memory_store
  config.active_storage.service = :test
  config.action_mailer.delivery_method = :test
  config.active_job.queue_adapter = :test
  config.active_support.deprecation = :stderr
end
