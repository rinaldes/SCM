class AddExtraChargeAmountInSales < ActiveRecord::Migration
  def change
    add_column :sales, :total_extra_charge, :float
  end
end
