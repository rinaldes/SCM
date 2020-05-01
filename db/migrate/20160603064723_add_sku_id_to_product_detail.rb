class AddSkuIdToProductDetail < ActiveRecord::Migration
  def change
    add_column :product_details, :sku_id, :integer
  end
end
