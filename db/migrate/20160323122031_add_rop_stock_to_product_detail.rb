class AddRopStockToProductDetail < ActiveRecord::Migration
  def change
    add_column :product_details, :rop_stock, :integer
  end
end
