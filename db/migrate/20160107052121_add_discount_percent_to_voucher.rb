class AddDiscountPercentToVoucher < ActiveRecord::Migration
  def change
    add_column :vouchers, :discount_percent, :float
  end
end
