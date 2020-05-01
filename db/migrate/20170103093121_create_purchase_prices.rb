class CreatePurchasePrices < ActiveRecord::Migration
  def change
    create_table :purchase_prices do |t|
      t.integer :product_id
      t.date :start_date
      t.date :end_date
      t.integer :unit_id
      t.float :total_discount
      t.float :total_price_cost
      t.float :total_unit_cost
      t.float :price
      t.timestamps
    end
  end
end
