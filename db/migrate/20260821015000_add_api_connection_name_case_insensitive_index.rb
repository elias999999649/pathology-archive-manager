class AddApiConnectionNameCaseInsensitiveIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :api_connections, :name
    add_index :api_connections, "LOWER(name)", unique: true, name: "index_api_connections_on_lower_name"
  end
end
