class AddDefaultQtyToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :default_qty, :boolean
  end
end
