class NewFieldForVoucher < ActiveRecord::Migration
  def change
    add_column :vouchers, :voucher_code, :string
    add_column :vouchers, :used_date, :timestamp
  end
end