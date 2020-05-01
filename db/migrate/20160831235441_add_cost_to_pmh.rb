class AddCostToPmh < ActiveRecord::Migration
  def change
    add_column :product_mutation_histories, :cost, :float
    add_column :product_mutation_histories, :avg_cost, :float
    add_column :product_mutation_histories, :last_cost, :float
    add_column :daily_sales_inventories, :cost, :float
    add_column :daily_sales_inventories, :avg_cost, :float
    add_column :daily_sales_inventories, :last_cost, :float
  end
end
