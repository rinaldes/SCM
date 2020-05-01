class AddDefaultToAp < ActiveRecord::Migration
  def change
    change_column :account_payables, :total_paid, :float, default: 0
    change_column :account_payables, :retur_amount, :float, default: 0
    change_column :account_payables, :total_discount, :float, default: 0
  end
end
