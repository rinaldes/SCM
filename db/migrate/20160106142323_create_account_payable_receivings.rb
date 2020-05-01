class CreateAccountPayableReceivings < ActiveRecord::Migration
  def change
    create_table :account_payable_receivings do |t|
      t.integer :receiving_id
      t.integer :account_payable_id
      t.timestamps
    end
  end
end
