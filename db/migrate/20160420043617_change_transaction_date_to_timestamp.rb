class ChangeTransactionDateToTimestamp < ActiveRecord::Migration
  def change
    change_column :sales, :transaction_date, :datetime
  end
end
