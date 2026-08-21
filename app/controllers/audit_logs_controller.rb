class AuditLogsController < ApplicationController
  PER_PAGE = 25

  def index
    authorize AuditLog
    @users = User.order(:email)
    @resource_types = AuditLog.where.not(auditable_type: nil).distinct.order(:auditable_type).pluck(:auditable_type)
    @filters = filter_params.to_h
    @page = [params.fetch(:page, 1).to_i, 1].max
    @audit_logs = AuditLogSearch.new(@filters).call.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
    @has_next = @audit_logs.length > PER_PAGE
    @audit_logs = @audit_logs.first(PER_PAGE)
  end

  def show
    @audit_log = AuditLog.find(params[:id])
    authorize @audit_log
  end

  private

  def filter_params
    params.permit(:q, :user_id, :event_type, :slide_id, :date, :resource)
  end
end
