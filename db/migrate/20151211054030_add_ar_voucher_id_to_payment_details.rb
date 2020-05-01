class AddArVoucherIdToPaymentDetails < ActiveRecord::Migration
  def change
    add_column :ar_voucher_payment_schedules, :ar_voucher_id, :integer
  end
end
