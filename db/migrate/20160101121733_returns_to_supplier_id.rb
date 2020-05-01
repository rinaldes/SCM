class ReturnsToSupplierId < ActiveRecord::Migration
  def change
    add_column :returns_to_supplier_details, :returns_to_supplier_id, :integer
  end
end
