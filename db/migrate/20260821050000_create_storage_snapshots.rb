class CreateStorageSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :storage_snapshots, id: :uuid do |t|
      t.string :provider_name, null: false
      t.bigint :total_bytes
      t.bigint :used_bytes
      t.bigint :free_bytes
      t.decimal :usage_percentage, precision: 6, scale: 2
      t.string :status, null: false, default: "unconfigured"
      t.datetime :checked_at, null: false
      t.text :error
      t.integer :slide_count, null: false, default: 0
      t.bigint :growth_bytes_per_day
      t.integer :estimated_remaining_days
      t.jsonb :by_slide_type, null: false, default: {}
      t.jsonb :by_hospital, null: false, default: {}
      t.timestamps
    end

    add_index :storage_snapshots, :checked_at
    add_index :storage_snapshots, :status
    add_check_constraint :storage_snapshots, "status IN ('unconfigured', 'healthy', 'warning_80', 'warning_90', 'critical_95', 'error')", name: "storage_snapshots_status_valid"
    add_check_constraint :storage_snapshots, "usage_percentage IS NULL OR (usage_percentage >= 0 AND usage_percentage <= 100)", name: "storage_snapshots_usage_valid"
  end
end
