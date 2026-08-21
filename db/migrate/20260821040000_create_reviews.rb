class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews, id: :uuid do |t|
      t.references :slide, type: :uuid, null: false, foreign_key: true
      t.references :reviewer, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.string :decision, null: false
      t.text :comment
      t.jsonb :previous_state, null: false, default: {}
      t.string :retention_policy_code
      t.string :tags_added, array: true, null: false, default: []
      t.datetime :decided_at, null: false
      t.timestamps
    end

    add_index :reviews, [:slide_id, :decided_at]
    add_index :reviews, :decision
    add_check_constraint :reviews, "decision IN ('keep', 'delete')", name: "reviews_decision_valid"
  end
end
