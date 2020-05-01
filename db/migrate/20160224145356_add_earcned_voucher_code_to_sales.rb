class AddEarcnedVoucherCodeToSales < ActiveRecord::Migration
  def change
    add_column :sales, :earned_voucher_id, :integer
  end
end
