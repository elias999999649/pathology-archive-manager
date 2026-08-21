class RetentionExpirationJob < ApplicationJob
  queue_as :default

  def perform(as_of = Time.current)
    RetentionExpirationService.call(as_of: as_of)
  end
end
