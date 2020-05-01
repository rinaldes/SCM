class AddAmountToATable < ActiveRecord::Migration
  def change
    add_column :ar_voucher_payment_schedules, :amount, :integer
  end
end
