class CreateProductMutationDetails < ActiveRecord::Migration
  def change
    create_table :product_mutation_details do |t|
      t.integer :product_size_id
      t.integer :quantity
      t.timestamps
    end
  end
end
