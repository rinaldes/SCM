class CreateInventoryReceiptDetails < ActiveRecord::Migration
  def change
    create_table :inventory_receipt_details do |t|
      t.integer :inventory_receipt_id
    	t.integer	:product_id
    	t.integer	:total_price
    	t.integer	:total_qty
    	t.string	:quantity_array
      t.timestamps
    end
  end
end
