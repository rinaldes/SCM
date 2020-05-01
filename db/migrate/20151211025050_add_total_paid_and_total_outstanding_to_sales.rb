class AddTotalPaidAndTotalOutstandingToSales < ActiveRecord::Migration
  def change
    add_column :sales, :total_paid, :float
    add_column :sales, :total_outstanding, :float
  end
end
