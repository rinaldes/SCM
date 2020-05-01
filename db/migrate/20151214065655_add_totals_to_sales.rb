class AddTotalsToSales < ActiveRecord::Migration
  def change
    add_column :sales, :total_quantity, :integer
    add_column :sales, :total_capital, :float
  end
end
