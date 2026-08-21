class AddRetentionTrackingToSlides < ActiveRecord::Migration[8.0]
  def change
    change_table :slides, bulk: true do |t|
      t.references :retention_policy, type: :uuid, foreign_key: true
      t.references :retention_rule, type: :uuid, foreign_key: { to_table: :archive_rules }
      t.datetime :retention_started_at
      t.string :retention_status, null: false, default: "not_scheduled"
      t.jsonb :retention_duration, null: false, default: {}
    end

    add_index :slides, :retention_status
    add_index :slides, [:retention_status, :retention_expires_at]
    add_index :slides, :retention_duration, using: :gin
    add_check_constraint :slides, "retention_status IN ('not_scheduled', 'scheduled', 'forever', 'eligible_for_deletion')", name: "slides_retention_status_valid"
  end
end
