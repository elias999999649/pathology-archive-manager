class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs, id: :uuid do |t|
      t.string :event_type, null: false
      t.references :actor, type: :uuid, foreign_key: { to_table: :users }
      t.string :auditable_type
      t.uuid :auditable_id
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :audit_logs, :event_type
    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :created_at
    add_index :audit_logs, :metadata, using: :gin
  end
end
