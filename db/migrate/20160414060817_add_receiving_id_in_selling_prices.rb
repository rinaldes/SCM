class AddReceivingIdInSellingPrices < ActiveRecord::Migration
  def change
    add_column :selling_prices, :receiving_id, :integer
  end
end
