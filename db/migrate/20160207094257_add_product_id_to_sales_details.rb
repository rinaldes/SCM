class AddProductIdToSalesDetails < ActiveRecord::Migration
  def change
    add_column :sales_details, :product_id, :integer
    add_column :sales_details, :product_detail_id, :integer
  end
end
