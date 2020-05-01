class AddSkuIdToProduct < ActiveRecord::Migration
  def change
    add_column :sales_details, :sku_id, :integer
  end
end
