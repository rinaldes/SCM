class AddTotalQtyToPo < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :total_qty, :integer
  end
end
