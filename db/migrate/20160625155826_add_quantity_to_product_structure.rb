class AddQuantityToProductStructure < ActiveRecord::Migration
  def change
    add_column :product_structures, :quantity, :float
  end
end
