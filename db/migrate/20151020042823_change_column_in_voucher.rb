class ChangeColumnInVoucher < ActiveRecord::Migration
  def change
    rename_column :vouchers, :max_Voucher, :max_voucher
  end
end
