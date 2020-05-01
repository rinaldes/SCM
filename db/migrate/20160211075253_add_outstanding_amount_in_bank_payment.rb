class AddOutstandingAmountInBankPayment < ActiveRecord::Migration
  def change
    add_column :sales_payment_bank, :outstanding_amount, :float
  end
end
