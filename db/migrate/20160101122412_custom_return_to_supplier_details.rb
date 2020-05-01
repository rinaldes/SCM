class CustomReturnToSupplierDetails < ActiveRecord::Migration
  def change
=begin
    remove_column :returns_to_supplier_details, :code
    remove_column :returns_to_supplier_details, :brand
    remove_column :returns_to_supplier_details, :article
    remove_column :returns_to_supplier_details, :color
    remove_column :returns_to_supplier_details, :dept
=end
    add_column :returns_to_supplier_details, :product_size_id, :integer
  end
end
