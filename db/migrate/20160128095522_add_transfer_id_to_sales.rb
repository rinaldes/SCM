class AddTransferIdToSales < ActiveRecord::Migration
  def change
    add_column :sales, :transfer_id, :integer
    add_column :sales, :transfer_amt, :float
  end
end
