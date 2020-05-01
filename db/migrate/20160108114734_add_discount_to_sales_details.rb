class AddDiscountToSalesDetails < ActiveRecord::Migration
  def change
    add_column :product_mutation_histories, :discount, :float
  end
end
