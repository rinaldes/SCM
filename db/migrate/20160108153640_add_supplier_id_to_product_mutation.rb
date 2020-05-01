class AddSupplierIdToProductMutation < ActiveRecord::Migration
  def change
    add_column :product_mutations, :supplier_id, :integer
  end
end
