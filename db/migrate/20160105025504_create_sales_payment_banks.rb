class CreateSalesPaymentBanks < ActiveRecord::Migration
  def change
    create_table :sales_payment_bank do |t|
      t.integer :sales_id
      t.string :type
      t.string :bank_name
      t.string :account_number
      t.string :card_number
      t.float :payment_amt
      t.timestamps
    end
  end
end
