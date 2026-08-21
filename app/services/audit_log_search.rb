class AuditLogSearch
  EVENT_TYPES = AuditLog::EVENT_TYPES

  def initialize(params = {})
    @params = params
  end

  def call
    scope = AuditLog.includes(:actor).newest_first
    scope = scope.where(actor_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where(event_type: params[:event_type]) if params[:event_type].present?
    scope = scope.where(auditable_type: params[:resource]) if params[:resource].present?
    if params[:slide_id].present?
      slide_query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:slide_id].to_s.strip)}%"
      scope = scope.where("audit_logs.auditable_id::text ILIKE :slide OR (audit_logs.auditable_type = 'Slide' AND EXISTS (SELECT 1 FROM slides WHERE slides.id = audit_logs.auditable_id AND slides.slide_uid ILIKE :slide))", slide: slide_query)
    end
    scope = scope.where(created_at: date.beginning_of_day..date.end_of_day) if date

    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
      scope = scope.where(<<~SQL.squish, q: query)
        audit_logs.event_type ILIKE :q OR audit_logs.auditable_type ILIKE :q
        OR audit_logs.auditable_id::text ILIKE :q OR audit_logs.metadata::text ILIKE :q
        OR EXISTS (SELECT 1 FROM users WHERE users.id = audit_logs.actor_id AND users.email ILIKE :q)
      SQL
    end

    scope
  end

  private

  attr_reader :params

  def date
    Date.parse(params[:date].to_s) if params[:date].present?
  rescue ArgumentError
    nil
  end
end
