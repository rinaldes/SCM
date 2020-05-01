class AddPajakToStockOpnameDetails < ActiveRecord::Migration
  def change
    add_column :stock_opname_details, :pajak, :float
  end
end
