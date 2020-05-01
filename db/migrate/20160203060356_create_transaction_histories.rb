class CreateTransactionHistories < ActiveRecord::Migration
  def change
    create_table :transaction_histories do |t|
      t.string :transaction_no
      t.date :date
      t.string :customer_name
      t.integer :item_qty
      t.float :transaction_amount
      t.float :total_paid
      t.float :exchange
      t.float :outstanding
      t.timestamps
    end
  end
end
