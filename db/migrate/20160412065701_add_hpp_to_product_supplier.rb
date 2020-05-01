class AddHppToProductSupplier < ActiveRecord::Migration
  def change
    add_column :product_suppliers, :hpp, :float
  end
end
