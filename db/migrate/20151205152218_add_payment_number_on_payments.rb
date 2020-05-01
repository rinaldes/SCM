class AddPaymentNumberOnPayments < ActiveRecord::Migration
  def change
    add_column :payments, :payment_number, :integer
  end
end
