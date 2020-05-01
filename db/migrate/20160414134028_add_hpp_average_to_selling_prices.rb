class AddHppAverageToSellingPrices < ActiveRecord::Migration
  def change
        add_column :selling_prices, :hpp_average, :float
  end
end
