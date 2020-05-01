class AddCashOnPettyCash < ActiveRecord::Migration
  def change
    add_column :petty_cashes, :end_amount, :float
    add_column :petty_cashes, :total_cash_sales, :float  	
    add_column :petty_cashes, :total_spending, :float
    add_column :petty_cashes, :petty_cash, :float
    add_column :petty_cashes, :difference, :float
    add_column :petty_cashes, :note, :text
    add_column :petty_cashes, :cash, :text
  end
end
