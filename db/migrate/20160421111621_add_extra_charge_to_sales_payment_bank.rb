class AddExtraChargeToSalesPaymentBank < ActiveRecord::Migration
  def change
    add_column :sales_payment_bank, :extra_charge, :string
  end
end
