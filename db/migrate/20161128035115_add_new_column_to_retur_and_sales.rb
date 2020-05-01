class AddNewColumnToReturAndSales < ActiveRecord::Migration
  def change
    ReturnsToSupplier.reset_column_information
    Sale.reset_column_information
  	add_column :returns_to_suppliers, :sent_to_erp, :datetime unless ReturnsToSupplier.column_names.include?('sent_to_erp')
  	add_column :sales, :sent_to_erp, :datetime unless Sale.column_names.include?('sent_to_erp')
  end
end
