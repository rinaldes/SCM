class AddPurchasePriceDateToProducts < ActiveRecord::Migration
  def change
    add_column :products, :purchase_price_date, :date
  end
end
