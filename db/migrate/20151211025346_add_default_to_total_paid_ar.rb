class AddDefaultToTotalPaidAr < ActiveRecord::Migration
  def change
    change_column :account_receivables, :total_paid, :float, default: 0
  end
end
