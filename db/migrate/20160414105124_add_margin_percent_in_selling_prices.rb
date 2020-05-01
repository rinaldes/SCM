class AddMarginPercentInSellingPrices < ActiveRecord::Migration
  def change
    add_column :selling_prices, :margin_percent, :float
  end
end
