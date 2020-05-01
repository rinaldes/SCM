class AddPaymentTempoOnAp < ActiveRecord::Migration
  def change
    add_column :account_payables, :payment_tempo, :string
  end
end
