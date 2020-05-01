class AddRedeemAmountToCd < ActiveRecord::Migration
  def change
    add_column :voucher_details, :reedem_amount, :float
  end
end
