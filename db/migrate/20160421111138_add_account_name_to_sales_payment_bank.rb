class AddAccountNameToSalesPaymentBank < ActiveRecord::Migration
  def change
    add_column :sales_payment_bank, :account_name, :string
  end
end
