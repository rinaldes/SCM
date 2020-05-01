class AddMaxStockProductDetail < ActiveRecord::Migration
  def change
    add_column :product_details, :max_stock, :integer
  end
end
