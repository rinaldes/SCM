class CreatePurchasePriceDiscounts < ActiveRecord::Migration
  def change
    create_table :purchase_price_discounts do |t|
      t.integer :purchase_price_id
      t.string :disc_rules
      t.string :disc_type
      t.float :disc_percentage
      t.float :disc_amount
      t.timestamps
    end
  end
end
