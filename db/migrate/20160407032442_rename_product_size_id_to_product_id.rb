class RenameProductSizeIdToProductId < ActiveRecord::Migration
  def change
    rename_column :stock_opname_details, :product_size_id, :product_id
  end
end
