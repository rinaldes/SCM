class AddTotalPpnInSales < ActiveRecord::Migration
  def change
    add_column :sales, :total_ppn, :float
  end
end
