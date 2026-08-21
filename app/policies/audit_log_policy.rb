class AuditLogPolicy < ApplicationPolicy
  def index? = administrator?
  def show? = administrator?

  private

  def administrator?
    user&.system_administrator? || user&.archive_administrator?
  end
end
