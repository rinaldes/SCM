class CreateBrPurchaseOrderDetails < ActiveRecord::Migration
  def change
    create_table :br_purchase_order_details do |t|
      t.integer :purchase_order_id
      t.integer :product_id
      t.float :total_price
      t.integer :quantity
      t.string :unit_type
      t.float :hpp
      t.timestamps
    end
  end
end
