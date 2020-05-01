class CreateProductStructures < ActiveRecord::Migration
  def change
    create_table :product_structures do |t|
      t.integer :sku_id
      t.integer :parent_id
      t.timestamps
    end
  end
end
