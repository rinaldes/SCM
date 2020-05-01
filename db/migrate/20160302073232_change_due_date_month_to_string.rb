class ChangeDueDateMonthToString < ActiveRecord::Migration
  def change
    change_column :ar_voucher_payment_schedules, :due_date_month, :string
  end
end
