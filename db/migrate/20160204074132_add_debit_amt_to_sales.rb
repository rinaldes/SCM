class AddDebitAmtToSales < ActiveRecord::Migration
  def change
    add_column :sales, :debit_amt, :float
    add_column :sales, :credit_amt, :float
    add_column :sales, :cashback_id, :integer
    add_column :sales, :cashback_amt, :float
   end
end
