class AddPajakToStockOpnames < ActiveRecord::Migration
  def change
    add_column :stock_opnames, :pajak, :float
  end
end
