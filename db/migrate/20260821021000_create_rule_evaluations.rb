class CreateRuleEvaluations < ActiveRecord::Migration[8.0]
  def change
    create_table :rule_evaluations, id: :uuid do |t|
      t.references :slide, type: :uuid, null: false, foreign_key: true
      t.references :winning_rule, type: :uuid, foreign_key: { to_table: :archive_rules }
      t.uuid :matched_rule_ids, array: true, null: false, default: []
      t.string :final_decision, null: false
      t.integer :retention_period
      t.text :reason, null: false
      t.jsonb :details, null: false, default: {}
      t.datetime :evaluated_at, null: false
      t.timestamps
    end

    add_index :rule_evaluations, :matched_rule_ids, using: :gin
    add_index :rule_evaluations, :final_decision
    add_index :rule_evaluations, :evaluated_at
    add_index :rule_evaluations, [:slide_id, :evaluated_at]
    add_check_constraint :rule_evaluations, "final_decision IN ('undecided', 'keep', 'delete', 'manual_review', 'keep_forever', 'delete_after_retention')", name: "rule_evaluations_decision_valid"
    add_check_constraint :rule_evaluations, "retention_period IS NULL OR retention_period > 0", name: "rule_evaluations_retention_positive"
  end
end
