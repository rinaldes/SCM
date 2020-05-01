class ChangeProductIdToProductSizeId < ActiveRecord::Migration
  def change
    rename_column :purchase_request_details, :product_id, :product_size_id
    add_column :purchase_request_details, :quantity, :integer
  end
end
