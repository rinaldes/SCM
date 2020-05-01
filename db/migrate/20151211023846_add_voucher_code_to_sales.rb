class AddVoucherCodeToSales < ActiveRecord::Migration
  def change
    add_column :sales, :voucher_code, :string
  end
end
