class AddDiscountAmtToVouchers < ActiveRecord::Migration
  def change
    add_column :vouchers, :discount_amt, :float
  end
end
