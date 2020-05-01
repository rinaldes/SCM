class CreateSellingPriceDetails < ActiveRecord::Migration
  def change
    create_table :selling_price_details do |t|
      t.integer :selling_price_id
      t.integer :sku_id
      t.float :price
      t.timestamps
    end
  end
end
