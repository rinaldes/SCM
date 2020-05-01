class CreateBrPurchaseRequestDetails < ActiveRecord::Migration
  def change
    create_table :br_purchase_request_details do |t|
      t.integer :purchase_request_id
      t.integer :product_id
      t.integer :quantity
      t.integer :approved_qty
      t.timestamps
    end
  end
end
