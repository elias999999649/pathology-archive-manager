class CreateArchiveRules < ActiveRecord::Migration[8.0]
  def change
    create_table :archive_rules, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.integer :priority, null: false, default: 0
      t.boolean :enabled, null: false, default: false
      t.jsonb :conditions, null: false, default: {}
      t.jsonb :actions, null: false, default: []
      t.integer :version, null: false, default: 1
      t.references :created_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :archive_rules, [:enabled, :priority]
    add_index :archive_rules, :conditions, using: :gin
    add_index :archive_rules, :actions, using: :gin
    add_check_constraint :archive_rules, "priority >= 0", name: "archive_rules_priority_non_negative"
    add_check_constraint :archive_rules, "version > 0", name: "archive_rules_version_positive"
  end
end
