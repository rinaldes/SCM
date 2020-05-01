class AddMaxVoucherAmtToVouchers < ActiveRecord::Migration
  def change
    add_column :vouchers, :max_voucher_amt, :float
  end
end
