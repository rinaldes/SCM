class AddIsActiveToSellingPrice < ActiveRecord::Migration
  def change
    add_column :selling_prices, :is_active, :boolean
  end
end
