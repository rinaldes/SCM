class CreateBrPurchaseOrders < ActiveRecord::Migration
  def change
    create_table :br_purchase_orders do |t|
      t.string :number
      t.date :date
      t.integer :supplier_id
      t.string :status
      t.float :grand_total
      t.text :note
      t.integer :purchase_request_id
      t.integer :head_office_id
      t.integer :total_qty
      t.integer :top
      t.date :expected_delivery_date
      t.date :due_date
      t.timestamps
    end
  end
end
