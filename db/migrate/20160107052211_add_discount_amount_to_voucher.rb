class AddDiscountAmountToVoucher < ActiveRecord::Migration
  def change
    add_column :vouchers, :discount_amount, :float
  end
end
