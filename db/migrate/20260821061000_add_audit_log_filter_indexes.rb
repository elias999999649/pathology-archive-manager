class AddAuditLogFilterIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :audit_logs, [:event_type, :created_at]
  end
end
