class AddDeletionWorkflowToSlides < ActiveRecord::Migration[8.0]
  def change
    change_table :slides, bulk: true do |t|
      t.string :deletion_status, null: false, default: "none"
      t.datetime :deletion_scheduled_at
      t.datetime :trashed_at
      t.datetime :permanently_deleted_at
    end

    add_index :slides, :deletion_status
    add_index :slides, [:deletion_status, :deletion_scheduled_at]
    add_check_constraint :slides, "deletion_status IN ('none', 'scheduled', 'eligible_for_trash', 'trashed', 'permanently_deleted')", name: "slides_deletion_status_valid"
  end
end
