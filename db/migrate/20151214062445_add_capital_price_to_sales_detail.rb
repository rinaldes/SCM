class AddCapitalPriceToSalesDetail < ActiveRecord::Migration
  def change
    add_column :sales_details, :capital_price, :float
  end
end
