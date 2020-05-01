class ChangeProductSizeToProductSizeId < ActiveRecord::Migration
  def change
   rename_column :purchase_request_details, :product_size_id, :product_id
  end
end
