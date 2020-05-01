class CreateAccountReceivables < ActiveRecord::Migration
  def change
    create_table :account_receivables do |t|
      t.string :ar_number
      t.string :transaction_number
      t.integer :member_id
      t.float :total_amount
      t.float :total_paid
      t.float :outstanding
      t.date :due_date
      t.string :bill_to_name
      t.string :bill_to_email
      t.string :bill_to_phone
      t.string :bill_to_address
      t.integer :branch_id
      t.string :payment_term
      t.string :payment_discount
      t.timestamps
    end
  end
end
