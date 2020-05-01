class CreateStockTransferDetails < ActiveRecord::Migration
  def change
    create_table :stock_transfer_details do |t|
    	t.integer	:stock_transfer_id
    	t.integer	:product_detail_id
    	t.integer	:quantity
    	t.integer	:size_detail_id
      t.timestamps
    end
  end
end
