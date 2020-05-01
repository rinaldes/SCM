class CreateInventoryRequestDetails < ActiveRecord::Migration
  def change
    create_table :inventory_request_details do |t|
      t.integer :inventory_request_id
      t.integer :product_id
      t.integer :quantity
      t.integer :approved_quantity
      t.timestamps
    end
  end
end
