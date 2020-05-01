class CreateSbbcas < ActiveRecord::Migration
=begin
  def change
    create_table :sbbcas do |t|
      t.string :code
      t.string :payment_type
      t.date :transaction_date
      t.integer :sales_bill_id
      t.integer :member_id
      t.string :client_id
      t.string :bill_number
      t.string :voucher_code
      t.float :total_paid
      t.float :total_outstanding
      t.float :subtotal_price
      t.float :payment_cash
      t.float :exchange
      t.string :status
      t.float :voucher_amt
      t.integer :debit_id
      t.integer :credit_id
      t.integer :transfer_id
      t.float :transfer_amt
      t.float :debit_amt
      t.float :credit_amt
      t.integer :cashback_id
      t.float :cashback_amt
      t.float :total_extra_charge
      t.float :rounding_amt
      t.integer :earned_voucher_id
      t.float :total_special_discount
      t.integer :session_id
      t.float :total_ppn
      t.integer :receipt_count
      t.timestamps
    end
  end
=end
ActiveRecord::Base.connection.execute("CREATE TABLE sbbcas AS SELECT * FROM sales;")
end