class CreatePrTransferProducts < ActiveRecord::Migration
  def change
    create_table :pr_transfer_products do |t|
      t.integer :purchase_request_id
      t.integer :transfer_product_id
      t.integer :receiving_id
      t.timestamps
    end
  end
end
