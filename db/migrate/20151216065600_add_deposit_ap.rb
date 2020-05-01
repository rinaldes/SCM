class AddDepositAp < ActiveRecord::Migration
  def change
    add_column :account_payables, :deposit, :float
  end
end
