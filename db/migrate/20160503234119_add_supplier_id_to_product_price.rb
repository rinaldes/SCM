class AddSupplierIdToProductPrice < ActiveRecord::Migration
  def change
    add_column :selling_prices, :supplier_id, :integer
  end
end
