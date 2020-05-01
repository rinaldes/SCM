class AddAmountToVoucher < ActiveRecord::Migration
  def change
    add_column :vouchers, :amount, :float
  end
end
