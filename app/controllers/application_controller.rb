class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError do
    redirect_to authenticated_root_path, alert: "You are not authorized to perform that action."
  end

  helper_method :current_user

  def after_sign_in_path_for(_resource)
    AuditLogger.record!(event_type: "user.login", actor: current_user, metadata: { path: authenticated_root_path })
    authenticated_root_path
  end
end
