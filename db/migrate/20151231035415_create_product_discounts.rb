class CreateProductDiscounts < ActiveRecord::Migration
  def change
    create_table :product_discounts do |t|
      t.integer :product_id
      t.float :discount_amount
      t.float :sell_price
      t.float :discount_percent
      t.date :valid_from
      t.date :valid_until
      t.timestamps
    end
  end
end
