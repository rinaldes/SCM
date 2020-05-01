class AddStatusToStockTransfer < ActiveRecord::Migration
  def change
    add_column :stock_transfers, :old_status, :string
    add_column :stock_transfers, :new_status, :string
  end
end
