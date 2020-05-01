class AddPriceToStockOpnameDetails < ActiveRecord::Migration
  def change
    add_column :stock_opname_details, :price, :float
  end
end
