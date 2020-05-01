class CreateAccountPayableDetails < ActiveRecord::Migration
  def change
    create_table :account_payable_details do |t|
      t.integer :account_payable_id
      t.float :amount
      t.date :payment_date
      t.string :method #Giro, Cash
      t.string :bank
      t.string :giro_number
      t.string :note
      t.timestamps
    end
  end
end
