class AddVoucherNumber < ActiveRecord::Migration
  def change
    add_column :vouchers, :voucher_number, :integer
  end
end