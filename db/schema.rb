# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_21_062000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "api_connections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "authentication_method", default: "none", null: false
    t.string "base_url", default: "", null: false
    t.datetime "created_at", null: false
    t.text "credentials"
    t.boolean "enabled", default: true, null: false
    t.text "last_error"
    t.datetime "last_successful_sync_at"
    t.string "name", null: false
    t.string "status", default: "unknown", null: false
    t.integer "sync_interval", default: 60, null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_api_connections_on_lower_name", unique: true
    t.index ["enabled"], name: "index_api_connections_on_enabled"
    t.index ["status"], name: "index_api_connections_on_status"
    t.check_constraint "authentication_method::text = ANY (ARRAY['none'::character varying, 'api_key'::character varying, 'bearer_token'::character varying, 'basic_auth'::character varying]::text[])", name: "api_connections_auth_method_valid"
    t.check_constraint "status::text = ANY (ARRAY['unknown'::character varying, 'testing'::character varying, 'syncing'::character varying, 'healthy'::character varying, 'error'::character varying, 'disabled'::character varying]::text[])", name: "api_connections_status_valid"
    t.check_constraint "sync_interval > 0", name: "api_connections_sync_interval_positive"
  end

  create_table "archive_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "actions", default: [], null: false
    t.jsonb "conditions", default: {}, null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id", null: false
    t.text "description"
    t.boolean "enabled", default: false, null: false
    t.string "name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "updated_at", null: false
    t.uuid "updated_by_id", null: false
    t.integer "version", default: 1, null: false
    t.index ["actions"], name: "index_archive_rules_on_actions", using: :gin
    t.index ["conditions"], name: "index_archive_rules_on_conditions", using: :gin
    t.index ["created_by_id"], name: "index_archive_rules_on_created_by_id"
    t.index ["enabled", "priority"], name: "index_archive_rules_on_enabled_and_priority"
    t.index ["updated_by_id"], name: "index_archive_rules_on_updated_by_id"
    t.check_constraint "priority >= 0", name: "archive_rules_priority_non_negative"
    t.check_constraint "version > 0", name: "archive_rules_version_positive"
  end

  create_table "audit_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "actor_id"
    t.uuid "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_audit_logs_on_actor_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["event_type", "created_at"], name: "index_audit_logs_on_event_type_and_created_at"
    t.index ["event_type"], name: "index_audit_logs_on_event_type"
    t.index ["metadata"], name: "index_audit_logs_on_metadata", using: :gin
  end

  create_table "retention_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "duration_unit", null: false
    t.integer "duration_value"
    t.boolean "enabled", default: true, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_retention_policies_on_code", unique: true
    t.check_constraint "duration_unit::text = 'forever'::text AND duration_value IS NULL OR duration_unit::text <> 'forever'::text AND duration_value > 0", name: "retention_policies_value_valid"
    t.check_constraint "duration_unit::text = ANY (ARRAY['days'::character varying, 'months'::character varying, 'years'::character varying, 'forever'::character varying]::text[])", name: "retention_policies_unit_valid"
  end

  create_table "reviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "decided_at", null: false
    t.string "decision", null: false
    t.jsonb "previous_state", default: {}, null: false
    t.string "retention_policy_code"
    t.uuid "reviewer_id", null: false
    t.uuid "slide_id", null: false
    t.string "tags_added", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.index ["decision"], name: "index_reviews_on_decision"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
    t.index ["slide_id", "decided_at"], name: "index_reviews_on_slide_id_and_decided_at"
    t.index ["slide_id"], name: "index_reviews_on_slide_id"
    t.check_constraint "decision::text = ANY (ARRAY['keep'::character varying, 'delete'::character varying]::text[])", name: "reviews_decision_valid"
  end

  create_table "rule_evaluations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}, null: false
    t.datetime "evaluated_at", null: false
    t.string "final_decision", null: false
    t.uuid "matched_rule_ids", default: [], null: false, array: true
    t.text "reason", null: false
    t.integer "retention_period"
    t.uuid "slide_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "winning_rule_id"
    t.index ["evaluated_at"], name: "index_rule_evaluations_on_evaluated_at"
    t.index ["final_decision"], name: "index_rule_evaluations_on_final_decision"
    t.index ["matched_rule_ids"], name: "index_rule_evaluations_on_matched_rule_ids", using: :gin
    t.index ["slide_id", "evaluated_at"], name: "index_rule_evaluations_on_slide_id_and_evaluated_at"
    t.index ["slide_id"], name: "index_rule_evaluations_on_slide_id"
    t.index ["winning_rule_id"], name: "index_rule_evaluations_on_winning_rule_id"
    t.check_constraint "final_decision::text = ANY (ARRAY['undecided'::character varying, 'keep'::character varying, 'delete'::character varying, 'manual_review'::character varying, 'keep_forever'::character varying, 'delete_after_retention'::character varying]::text[])", name: "rule_evaluations_decision_valid"
    t.check_constraint "retention_period IS NULL OR retention_period > 0", name: "rule_evaluations_retention_positive"
  end

  create_table "slides", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "acquisition_date"
    t.string "barcode"
    t.string "case_id", null: false
    t.datetime "created_at", null: false
    t.string "decision", default: "undecided", null: false
    t.text "decision_reason"
    t.datetime "deletion_scheduled_at"
    t.string "deletion_status", default: "none", null: false
    t.string "department"
    t.text "diagnosis"
    t.bigint "file_size"
    t.string "hospital"
    t.jsonb "metadata", default: {}, null: false
    t.string "patient_id"
    t.datetime "permanently_deleted_at"
    t.datetime "received_at", null: false
    t.jsonb "retention_duration", default: {}, null: false
    t.datetime "retention_expires_at"
    t.integer "retention_period"
    t.uuid "retention_policy_id"
    t.uuid "retention_rule_id"
    t.datetime "retention_started_at"
    t.string "retention_status", default: "not_scheduled", null: false
    t.string "scanner"
    t.string "slide_type"
    t.string "slide_uid", null: false
    t.uuid "source_api_connection_id"
    t.string "stain"
    t.string "status", default: "received", null: false
    t.string "storage_path"
    t.string "tags", default: [], null: false, array: true
    t.datetime "trashed_at"
    t.datetime "updated_at", null: false
    t.index ["acquisition_date", "received_at"], name: "index_slides_on_acquisition_received"
    t.index ["acquisition_date"], name: "index_slides_on_acquisition_date"
    t.index ["barcode"], name: "index_slides_on_barcode"
    t.index ["barcode"], name: "index_slides_on_barcode_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["case_id"], name: "index_slides_on_case_id"
    t.index ["case_id"], name: "index_slides_on_case_id_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["decision"], name: "index_slides_on_decision"
    t.index ["deletion_status", "deletion_scheduled_at"], name: "index_slides_on_deletion_status_and_deletion_scheduled_at"
    t.index ["deletion_status"], name: "index_slides_on_deletion_status"
    t.index ["department"], name: "index_slides_on_department"
    t.index ["department"], name: "index_slides_on_department_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["hospital", "department"], name: "index_slides_on_hospital_and_department"
    t.index ["hospital"], name: "index_slides_on_hospital"
    t.index ["hospital"], name: "index_slides_on_hospital_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["metadata"], name: "index_slides_on_metadata", using: :gin
    t.index ["patient_id"], name: "index_slides_on_patient_id"
    t.index ["patient_id"], name: "index_slides_on_patient_id_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["received_at"], name: "index_slides_on_received_at"
    t.index ["retention_duration"], name: "index_slides_on_retention_duration", using: :gin
    t.index ["retention_expires_at"], name: "index_slides_on_retention_expires_at"
    t.index ["retention_policy_id"], name: "index_slides_on_retention_policy_id"
    t.index ["retention_rule_id"], name: "index_slides_on_retention_rule_id"
    t.index ["retention_status", "retention_expires_at"], name: "index_slides_on_retention_status_and_retention_expires_at"
    t.index ["retention_status"], name: "index_slides_on_retention_status"
    t.index ["scanner"], name: "index_slides_on_scanner"
    t.index ["scanner"], name: "index_slides_on_scanner_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["slide_type"], name: "index_slides_on_slide_type"
    t.index ["slide_type"], name: "index_slides_on_slide_type_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["slide_uid"], name: "index_slides_on_slide_uid", unique: true
    t.index ["slide_uid"], name: "index_slides_on_slide_uid_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["source_api_connection_id"], name: "index_slides_on_source_api_connection_id"
    t.index ["stain"], name: "index_slides_on_stain"
    t.index ["stain"], name: "index_slides_on_stain_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["status", "decision", "received_at"], name: "index_slides_on_status_decision_received"
    t.index ["status"], name: "index_slides_on_status"
    t.index ["tags"], name: "index_slides_on_tags", using: :gin
    t.check_constraint "(status::text = ANY (ARRAY['received'::character varying, 'available'::character varying, 'under_review'::character varying, 'archived'::character varying, 'deleted'::character varying]::text[])) AND (decision::text = ANY (ARRAY['undecided'::character varying, 'keep'::character varying, 'delete'::character varying, 'manual_review'::character varying, 'keep_forever'::character varying, 'delete_after_retention'::character varying]::text[])) AND (status::text <> 'deleted'::text OR decision::text = 'delete'::text) AND (decision::text <> 'delete'::text OR (status::text = ANY (ARRAY['received'::character varying, 'available'::character varying, 'deleted'::character varying]::text[]))) AND (status::text <> 'under_review'::text OR (decision::text = ANY (ARRAY['undecided'::character varying, 'manual_review'::character varying]::text[]))) AND (status::text <> 'archived'::text OR (decision::text = ANY (ARRAY['keep'::character varying, 'keep_forever'::character varying, 'delete_after_retention'::character varying]::text[]))) AND (decision::text <> 'manual_review'::text OR (status::text = ANY (ARRAY['received'::character varying, 'available'::character varying, 'under_review'::character varying]::text[]))) AND (decision::text <> 'delete_after_retention'::text OR retention_period IS NOT NULL) AND (decision::text <> 'keep_forever'::text OR retention_expires_at IS NULL)", name: "slides_status_decision_consistent"
    t.check_constraint "deletion_status::text = ANY (ARRAY['none'::character varying, 'scheduled'::character varying, 'eligible_for_trash'::character varying, 'trashed'::character varying, 'permanently_deleted'::character varying]::text[])", name: "slides_deletion_status_valid"
    t.check_constraint "file_size IS NULL OR file_size >= 0", name: "slides_file_size_non_negative"
    t.check_constraint "retention_period IS NULL OR retention_period > 0", name: "slides_retention_period_positive"
    t.check_constraint "retention_status::text = ANY (ARRAY['not_scheduled'::character varying, 'scheduled'::character varying, 'forever'::character varying, 'eligible_for_deletion'::character varying]::text[])", name: "slides_retention_status_valid"
  end

  create_table "storage_snapshots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "by_hospital", default: {}, null: false
    t.jsonb "by_slide_type", default: {}, null: false
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.text "error"
    t.integer "estimated_remaining_days"
    t.bigint "free_bytes"
    t.bigint "growth_bytes_per_day"
    t.string "provider_name", null: false
    t.integer "slide_count", default: 0, null: false
    t.string "status", default: "unconfigured", null: false
    t.bigint "total_bytes"
    t.datetime "updated_at", null: false
    t.decimal "usage_percentage", precision: 6, scale: 2
    t.bigint "used_bytes"
    t.index ["checked_at"], name: "index_storage_snapshots_on_checked_at"
    t.index ["status"], name: "index_storage_snapshots_on_status"
    t.check_constraint "status::text = ANY (ARRAY['unconfigured'::character varying, 'healthy'::character varying, 'warning_80'::character varying, 'warning_90'::character varying, 'critical_95'::character varying, 'error'::character varying]::text[])", name: "storage_snapshots_status_valid"
    t.check_constraint "usage_percentage IS NULL OR usage_percentage >= 0::numeric AND usage_percentage <= 100::numeric", name: "storage_snapshots_usage_valid"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 3, null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.check_constraint "role = ANY (ARRAY[0, 1, 2, 3])", name: "users_role_valid"
  end

  add_foreign_key "archive_rules", "users", column: "created_by_id"
  add_foreign_key "archive_rules", "users", column: "updated_by_id"
  add_foreign_key "audit_logs", "users", column: "actor_id"
  add_foreign_key "reviews", "slides"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "rule_evaluations", "archive_rules", column: "winning_rule_id"
  add_foreign_key "rule_evaluations", "slides"
  add_foreign_key "slides", "api_connections", column: "source_api_connection_id"
  add_foreign_key "slides", "archive_rules", column: "retention_rule_id"
  add_foreign_key "slides", "retention_policies"
end
