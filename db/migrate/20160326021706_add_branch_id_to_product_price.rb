class AddBranchIdToProductPrice < ActiveRecord::Migration
  def change
    add_column :selling_prices, :branch_id, :integer
  end
end
