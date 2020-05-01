class ChangeProductSizeToProductPo < ActiveRecord::Migration
  def change
    rename_column :purchase_order_details, :product_size_id, :product_id
  end
end
