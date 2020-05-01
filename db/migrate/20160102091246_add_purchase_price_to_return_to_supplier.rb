class AddPurchasePriceToReturnToSupplier < ActiveRecord::Migration
  def change
    add_column :returns_to_supplier_details, :purchase_price, :float
  end
end
