class ApiConnectionTestService
  Result = Data.define(:success, :message)

  def self.call(connection, actor: nil)
    connection.update!(status: "testing", last_error: nil)
    ExternalPathologyApi::Registry.build(connection).test_connection
    connection.update!(status: "healthy")
    AuditLogger.record!(event_type: "api_connection.test_succeeded", auditable: connection, actor: actor)
    Result.new(true, "Connection test succeeded.")
  rescue StandardError => e
    safe_error = ApiConnectionSyncService.safe_error_message(e, connection: connection)
    connection.update_columns(status: "error", last_error: safe_error, updated_at: Time.current)
    AuditLogger.record!(event_type: "api_connection.test_failed", auditable: connection, actor: actor, metadata: { error_class: e.class.name })
    Result.new(false, "Connection test failed. Check the connection status for details.")
  end
end
