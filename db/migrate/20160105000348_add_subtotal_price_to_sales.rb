class AddSubtotalPriceToSales < ActiveRecord::Migration
  def change
    add_column :sales, :subtotal_price, :float
    add_column :sales, :payment_cash, :float
    add_column :sales, :exchange, :float
    add_column :sales, :status, :string
    add_column :sales, :voucher_amt, :float
    add_column :sales_details, :discount_amt, :float
    add_column :sales_details, :total_discount_amt, :float
    add_column :sales_details, :subtotal_price, :float
  end
end
