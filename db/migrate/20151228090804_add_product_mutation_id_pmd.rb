class AddProductMutationIdPmd < ActiveRecord::Migration
  def change
    add_column :product_mutation_details, :product_mutation_id, :integer
  end
end
