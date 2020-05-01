class AddTotalPriceToSalesDetail < ActiveRecord::Migration
  def change
    add_column :sales_details, :total_price, :float
  end
end
