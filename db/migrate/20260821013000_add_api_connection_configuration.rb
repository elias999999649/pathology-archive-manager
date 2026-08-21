class AddApiConnectionConfiguration < ActiveRecord::Migration[8.0]
  def change
    change_table :api_connections, bulk: true do |t|
      t.string :base_url, null: false, default: ""
      t.string :authentication_method, null: false, default: "none"
      t.text :credentials
      t.integer :sync_interval, null: false, default: 60
      t.datetime :last_successful_sync_at
      t.text :last_error
      t.string :status, null: false, default: "unknown"
    end

    add_index :api_connections, :enabled
    add_index :api_connections, :status
    add_check_constraint :api_connections, "sync_interval > 0", name: "api_connections_sync_interval_positive"
    add_check_constraint :api_connections, "authentication_method IN ('none', 'api_key', 'bearer_token', 'basic_auth')", name: "api_connections_auth_method_valid"
    add_check_constraint :api_connections, "status IN ('unknown', 'testing', 'syncing', 'healthy', 'error', 'disabled')", name: "api_connections_status_valid"
  end
end
