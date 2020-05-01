class AddAdditionMinStockToBranchPrice < ActiveRecord::Migration
  def change
    add_column :branch_prices, :additional_min_stock, :integer
  end
end
