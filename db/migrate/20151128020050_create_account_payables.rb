class CreateAccountPayables < ActiveRecord::Migration
  def change
    create_table :account_payables do |t|
      t.string :ap_number
      t.date :due_date
      t.integer :supplier_id
      t.float :total_amount
      t.float :total_paid
      t.float :outstanding_amount
      t.string :payment_term
      t.float :retur_amount
      t.float :total_discount
      t.integer :receiving_id
      t.timestamps
    end
  end
end
