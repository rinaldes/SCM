class RenamePsIdToPId < ActiveRecord::Migration
  def change
    rename_column :product_details, :product_size_id, :product_id
  end
end
