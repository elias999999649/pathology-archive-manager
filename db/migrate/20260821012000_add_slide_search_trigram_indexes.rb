class AddSlideSearchTrigramIndexes < ActiveRecord::Migration[8.0]
  SEARCH_COLUMNS = %i[slide_uid case_id patient_id barcode scanner hospital department slide_type stain].freeze

  def change
    enable_extension "pg_trgm"

    SEARCH_COLUMNS.each do |column|
      add_index :slides, column, using: :gin, opclass: { column => :gin_trgm_ops }, name: "index_slides_on_#{column}_trgm"
    end
  end
end
