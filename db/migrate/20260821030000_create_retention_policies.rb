class CreateRetentionPolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :retention_policies, id: :uuid do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :duration_unit, null: false
      t.integer :duration_value
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end

    add_index :retention_policies, :code, unique: true
    add_check_constraint :retention_policies, "duration_unit IN ('days', 'months', 'years', 'forever')", name: "retention_policies_unit_valid"
    add_check_constraint :retention_policies, "(duration_unit = 'forever' AND duration_value IS NULL) OR (duration_unit <> 'forever' AND duration_value > 0)", name: "retention_policies_value_valid"
  end
end
