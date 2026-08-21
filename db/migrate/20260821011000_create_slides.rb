class CreateSlides < ActiveRecord::Migration[8.0]
  def change
    create_table :slides, id: :uuid do |t|
      t.string :slide_uid, null: false
      t.string :case_id, null: false
      t.string :patient_id
      t.string :barcode
      t.string :scanner
      t.string :hospital
      t.string :department
      t.string :slide_type
      t.string :stain
      t.text :diagnosis
      t.date :acquisition_date
      t.datetime :received_at, null: false
      t.bigint :file_size
      t.string :storage_path
      t.string :status, null: false, default: "received"
      t.string :decision, null: false, default: "undecided"
      t.text :decision_reason
      t.integer :retention_period
      t.datetime :retention_expires_at
      t.jsonb :metadata, null: false, default: {}
      t.string :tags, array: true, null: false, default: []
      t.references :source_api_connection, type: :uuid, foreign_key: { to_table: :api_connections }
      t.timestamps
    end

    add_index :slides, :slide_uid, unique: true
    add_index :slides, :case_id
    add_index :slides, :patient_id
    add_index :slides, :barcode
    add_index :slides, :scanner
    add_index :slides, :hospital
    add_index :slides, :department
    add_index :slides, :slide_type
    add_index :slides, :stain
    add_index :slides, :status
    add_index :slides, :decision
    add_index :slides, :acquisition_date
    add_index :slides, :received_at
    add_index :slides, :retention_expires_at
    add_index :slides, :tags, using: :gin
    add_index :slides, :metadata, using: :gin
    add_index :slides, [:hospital, :department]

    add_check_constraint :slides, "file_size IS NULL OR file_size >= 0", name: "slides_file_size_non_negative"
    add_check_constraint :slides, "retention_period IS NULL OR retention_period > 0", name: "slides_retention_period_positive"
    add_check_constraint :slides, <<~SQL.squish, name: "slides_status_decision_consistent"
      status IN ('received', 'available', 'under_review', 'archived', 'deleted')
      AND decision IN ('undecided', 'keep', 'delete', 'manual_review', 'keep_forever', 'delete_after_retention')
      AND (status <> 'deleted' OR decision = 'delete')
      AND (decision <> 'delete' OR status IN ('received', 'available', 'deleted'))
      AND (status <> 'under_review' OR decision IN ('undecided', 'manual_review'))
      AND (status <> 'archived' OR decision IN ('keep', 'keep_forever', 'delete_after_retention'))
      AND (decision <> 'manual_review' OR status IN ('received', 'available', 'under_review'))
      AND (decision <> 'delete_after_retention' OR retention_period IS NOT NULL)
      AND (decision <> 'keep_forever' OR retention_expires_at IS NULL)
    SQL
  end
end
