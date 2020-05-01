class AddPajakToReturnsToSupplierDetails < ActiveRecord::Migration
  def change
    add_column :returns_to_supplier_details, :pajak, :float
  end
end
