class AddSupplierIdToMts < ActiveRecord::Migration
  def change
    add_column :stock_transfers, :supplier_id, :integer
  end
end
