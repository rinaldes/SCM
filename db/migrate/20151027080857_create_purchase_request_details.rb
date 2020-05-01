class CreatePurchaseRequestDetails < ActiveRecord::Migration
  def change
    create_table :purchase_request_details do |t|
    	t.integer	:purchase_request_id
    	t.integer	:product_id
      t.timestamps
    end
  end
end
