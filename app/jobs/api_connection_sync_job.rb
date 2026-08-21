class ApiConnectionSyncJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(api_connection_id)
    connection = ApiConnection.find(api_connection_id)
    ApiConnectionSyncService.call(connection)
  end
end
