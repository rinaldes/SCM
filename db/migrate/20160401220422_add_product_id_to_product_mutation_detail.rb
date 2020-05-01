class AddProductIdToProductMutationDetail < ActiveRecord::Migration
  def change
    add_column :product_mutation_details, :product_id, :integer
  end
end
