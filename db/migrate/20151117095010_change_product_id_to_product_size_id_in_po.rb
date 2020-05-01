class ChangeProductIdToProductSizeIdInPo < ActiveRecord::Migration
  def change
    rename_column :purchase_order_details, :total_qty, :quantity
    rename_column :purchase_order_details, :product_id, :product_size_id
  end
end
