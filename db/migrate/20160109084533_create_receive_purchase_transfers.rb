class CreateReceivePurchaseTransfers < ActiveRecord::Migration
  def change
    create_table :receive_purchase_transfers do |t|
      t.integer :receiving_id
      t.integer :purchase_transfer_id
      t.timestamps
    end
  end
end
