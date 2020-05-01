class CreateReceivingDetails < ActiveRecord::Migration
  def change
    create_table :receiving_details do |t|
    	t.integer :receiving_id
    	t.integer	:product_id
    	t.integer	:total_price
    	t.integer	:total_qty
    	t.string	:quantity_array
      t.timestamps
    end
  end
end
