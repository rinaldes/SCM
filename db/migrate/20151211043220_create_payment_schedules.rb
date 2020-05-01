class CreatePaymentSchedules < ActiveRecord::Migration
  def change
    create_table :payment_schedules do |t|
      t.string :code
      t.integer :amount
      t.date :due_date
      t.integer :voucher_credit_id
      t.timestamps
    end
  end
end
