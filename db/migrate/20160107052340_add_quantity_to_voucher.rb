class AddQuantityToVoucher < ActiveRecord::Migration
  def change
    add_column :vouchers, :quantity, :integer
  end
end
