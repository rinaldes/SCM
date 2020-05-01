class CreateInventoryReceipts < ActiveRecord::Migration
  def change
    create_table :inventory_receipts do |t|
      t.integer :supplier_id
      t.integer :branch_id
      t.integer :requester_id
      t.string :number
      t.date :date
      t.string :status
      t.integer :grand_total
      t.text :note
    end
  end
end
