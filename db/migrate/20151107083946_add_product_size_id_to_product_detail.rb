class AddProductSizeIdToProductDetail < ActiveRecord::Migration
  def change
    add_column :product_details, :product_size_id, :integer
    remove_column :product_details, :product_id, :integer
    remove_column :product_details, :size_detail_id, :integer
  end
end
