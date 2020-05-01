class CreateSales < ActiveRecord::Migration
  def change
    create_table :sales do |t|
      t.string :code
      t.string :payment_type
      t.date :transaction_date
      t.integer :sales_bill_id
      t.integer :member_id
      t.string :client_id
      t.string :bill_number
      t.integer :store_id
      t.float :total_price
      t.float :total_discount
      t.integer :user_id
      t.timestamps
    end
    add_index :sales, :payment_type
    add_index :sales, :transaction_date
    add_index :sales, :sales_bill_id
    add_index :sales, :member_id
    add_index :sales, :client_id
    add_index :sales, :store_id
    add_index :sales, :total_price
    add_index :sales, :total_discount
  end
end
