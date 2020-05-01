class AddSupplierIdToStockOpnames < ActiveRecord::Migration
  def change
    add_column :stock_opnames, :supplier_id, :integer
  end
end
