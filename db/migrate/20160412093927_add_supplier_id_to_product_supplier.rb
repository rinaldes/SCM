class AddSupplierIdToProductSupplier < ActiveRecord::Migration
  def change
    add_column :product_suppliers, :supplier_id, :integer
  end
end
