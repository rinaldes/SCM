class AddDebitIdToSales < ActiveRecord::Migration
  def change
    add_column :sales, :debit_id, :integer
    add_column :sales, :credit_id, :integer
  end
end
