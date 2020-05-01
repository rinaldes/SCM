class AddVoucherIdToVoucherDetails < ActiveRecord::Migration
  def change
    add_column :voucher_details, :voucher_id, :integer
  end
end
