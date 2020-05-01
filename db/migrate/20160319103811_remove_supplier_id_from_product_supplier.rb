class RemoveSupplierIdFromProductSupplier < ActiveRecord::Migration
  def change
    remove_column :product_suppliers, :supplier_id, :integer
  end
end
