class CreateBankAccounts < ActiveRecord::Migration
  def change
    create_table :bank_accounts do |t|
      t.string :name
      t.string :account_number
      t.string :bank_name
      t.string :branch
      t.integer :supplier_id
      t.timestamps
    end
  end
end
