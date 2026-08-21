module Settings
  class ApiConnectionsController < ApplicationController
    before_action :set_api_connection, except: [:index, :new, :create]

    def index
      authorize ApiConnection
      @api_connections = ApiConnection.order(:name)
    end

    def new
      @api_connection = ApiConnection.new(enabled: true, sync_interval: 60, authentication_method: "none")
      authorize @api_connection
    end

    def create
      @api_connection = ApiConnection.new(api_connection_params)
      authorize @api_connection
      if @api_connection.save
        AuditLogger.record!(event_type: "api_connection.created", auditable: @api_connection, actor: current_user)
        redirect_to settings_api_connections_path, notice: "API connection created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @api_connection
    end

    def update
      authorize @api_connection
      if @api_connection.update(api_connection_params)
        AuditLogger.record!(event_type: "api_connection.updated", auditable: @api_connection, actor: current_user)
        redirect_to settings_api_connections_path, notice: "API connection updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @api_connection
      @api_connection.destroy!
      AuditLogger.record!(event_type: "api_connection.deleted", auditable: @api_connection, actor: current_user)
      redirect_to settings_api_connections_path, notice: "API connection deleted."
    rescue ActiveRecord::RecordNotDestroyed
      redirect_to settings_api_connections_path, alert: "This connection cannot be deleted while slides reference it."
    end

    def toggle
      authorize @api_connection
      new_enabled = !@api_connection.enabled?
      @api_connection.update!(enabled: new_enabled, status: new_enabled ? "unknown" : "disabled")
      AuditLogger.record!(event_type: "api_connection.toggled", auditable: @api_connection, actor: current_user, metadata: { enabled: @api_connection.enabled? })
      redirect_to settings_api_connections_path, notice: "API connection #{@api_connection.enabled? ? 'enabled' : 'disabled'}."
    end

    def test
      authorize @api_connection
      result = ApiConnectionTestService.call(@api_connection, actor: current_user)
      redirect_to settings_api_connections_path, (result.success ? { notice: result.message } : { alert: result.message })
    end

    def sync
      authorize @api_connection
      if @api_connection.enabled?
        ApiConnectionSyncJob.perform_later(@api_connection.id)
        redirect_to settings_api_connections_path, notice: "Synchronization queued."
      else
        redirect_to settings_api_connections_path, alert: "Enable the connection before synchronizing."
      end
    end

    private

    def set_api_connection
      @api_connection = ApiConnection.find(params[:id])
    end

    def api_connection_params
      permitted = params.require(:api_connection).permit(:name, :base_url, :authentication_method, :enabled, :sync_interval, :credentials_token)
      token = permitted.delete(:credentials_token)
      permitted[:credentials] = { "token" => token } if token.present?
      permitted
    end
  end
end
