class AddDueDateToPo < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :due_date, :date
    add_column :sales_payment_bank, :edc_machine_id, :integer
  end
end
