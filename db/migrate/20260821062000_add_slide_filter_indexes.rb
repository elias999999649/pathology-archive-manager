class AddSlideFilterIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :slides, [:status, :decision, :received_at], name: "index_slides_on_status_decision_received"
    add_index :slides, [:acquisition_date, :received_at], name: "index_slides_on_acquisition_received"
  end
end
