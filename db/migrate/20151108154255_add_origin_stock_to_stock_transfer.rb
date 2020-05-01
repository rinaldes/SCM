class AddOriginStockToStockTransfer < ActiveRecord::Migration
  def change
    add_column :stock_transfers, :origin_stock, :string
    add_column :stock_transfers, :destination_stock, :string
  end
end
