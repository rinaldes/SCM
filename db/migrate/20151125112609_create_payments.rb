class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.float :amount
      t.date :due_date
      t.float :payment_amount
      t.date :payment_date
      t.float :penalty
      t.string :status, default: 'PENDING' #PENDING, EXECUTED
      t.integer :account_receivable_id
      t.timestamps
    end
  end
end
