class CreateArVoucherPaymentSchedules < ActiveRecord::Migration
  def change
    create_table :ar_voucher_payment_schedules do |t|
      t.integer :payment_number
      t.integer :due_date
      t.integer :due_date_number
      t.integer :due_date_month
      t.timestamps
    end
  end
end
