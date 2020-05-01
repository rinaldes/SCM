class AddOriginToStockTransfer < ActiveRecord::Migration
  def change
    rename_column :stock_transfers, :branch_id, :origin_id
    add_column :stock_transfers, :destination_id, :integer
  end
end
