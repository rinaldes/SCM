class RenameSizeDetailIdToProductId < ActiveRecord::Migration
  def change
    rename_column :stock_transfer_details, :size_detail_id, :product_id
  end
end
