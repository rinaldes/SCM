class AddWarehouseId < ActiveRecord::Migration
  def change
    add_column :stock_opnames, :warehouse_id, :integer
  end
end
