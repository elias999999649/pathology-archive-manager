class ApiConnectionSyncService
  Result = Data.define(:success, :imported_count, :message)

  def self.call(connection, actor: nil)
    new(connection, actor: actor).call
  end

  def self.safe_error_message(error, connection: nil)
    message = error.message.to_s.gsub(/(token|secret|password|credential|api[ _-]?key|authorization)\s*[:=]\s*\S+/i, '[REDACTED]')
    message = message.gsub(%r{(https?://)[^\s/@]+:[^\s/@]+@}i, '\1[REDACTED]@')
    Array(connection&.credentials&.values).compact.each { |secret| message = message.gsub(secret.to_s, '[REDACTED]') if secret.to_s.length >= 4 }
    "#{error.class.name.demodulize}: #{message}"
  end

  def initialize(connection, actor: nil)
    @connection = connection
    @actor = actor
  end

  def call
    return Result.new(false, 0, "Connection is disabled.") unless connection.enabled?

    connection.update!(status: "syncing", last_error: nil)
    AuditLogger.record!(event_type: "api_connection.sync_started", auditable: connection, actor: actor)
    slides = ExternalPathologyApi::Registry.build(connection).fetch_slide_metadata
    imported_count = Array(slides).length
    connection.update!(status: "healthy", last_successful_sync_at: Time.current, last_error: nil)
    AuditLogger.record!(event_type: "api_connection.sync_succeeded", auditable: connection, actor: actor, metadata: { imported_count: imported_count })
    Result.new(true, imported_count, "Synchronization completed.")
  rescue StandardError => e
    safe_error = self.class.safe_error_message(e, connection: connection)
    connection.update_columns(status: "error", last_error: safe_error, updated_at: Time.current)
    AuditLogger.record!(event_type: "api_connection.sync_failed", auditable: connection, actor: actor, metadata: { error_class: e.class.name })
    raise
  end

  private

  attr_reader :connection, :actor
end
