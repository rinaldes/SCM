class AddReceivedQtyToRc < ActiveRecord::Migration
  def change
    add_column :receivings, :received_qty, :integer
    add_column :receivings, :outstanding_qty, :integer
  end
end
