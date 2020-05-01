class CreateBrPurchaseRequests < ActiveRecord::Migration
  def change
    create_table :br_purchase_requests do |t|
      t.string :number
      t.date :date
      t.integer :supplier_id
      t.string :status
      t.float :grand_total
      t.text :note
      t.integer :branch_id
      t.integer :requester_id
      t.integer :purchase_order_id
      t.timestamps
    end
  end
end
