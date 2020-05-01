class RenameQtyToSystemStockInSod < ActiveRecord::Migration
  def change
    rename_column :stock_opname_details, :quantity, :system_stock
  end
end
