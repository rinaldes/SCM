class AddPriceToPmh < ActiveRecord::Migration
  def change
    add_column :product_mutation_histories, :price, :float
  end
end
