class AddPajakToReturnsToSuppliers < ActiveRecord::Migration
  def change
    add_column :returns_to_suppliers, :pajak, :float
  end
end
