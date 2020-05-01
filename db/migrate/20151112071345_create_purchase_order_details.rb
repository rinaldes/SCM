class CreatePurchaseOrderDetails < ActiveRecord::Migration
  def change
    create_table :purchase_order_details do |t|
    	t.integer :purchase_order_id
    	t.integer	:product_id
    	t.integer	:total_price
    	t.integer	:total_qty
    	t.string	:quantity_array
      t.timestamps
    end
  end
end
