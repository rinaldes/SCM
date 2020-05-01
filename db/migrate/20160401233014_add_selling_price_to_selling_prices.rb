class AddSellingPriceToSellingPrices < ActiveRecord::Migration
  def change
    add_column :selling_prices, :selling_price, :float
    add_column :selling_prices, :margin_amount, :float
  end
end
