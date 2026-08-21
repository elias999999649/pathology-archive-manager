class CreateApiConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :api_connections, id: :uuid do |t|
      t.string :name, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end

    add_index :api_connections, :name, unique: true
  end
end
