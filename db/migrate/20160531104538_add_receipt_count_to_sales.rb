class AddReceiptCountToSales < ActiveRecord::Migration
  def change
    add_column :sales, :receipt_count, :integer
  end
end
