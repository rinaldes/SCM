class AddSoTypeToStockOpnames < ActiveRecord::Migration
  def change
    add_column :stock_opnames, :so_type, :string
  end
end
