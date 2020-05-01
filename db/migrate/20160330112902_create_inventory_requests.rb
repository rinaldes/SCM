class CreateInventoryRequests < ActiveRecord::Migration
  def change
    create_table :inventory_requests do |t|
      t.string  :number
      t.date  :date
      t.string :status, default: "Ready For Inspection"
      t.integer :sub_total
      t.timestamps
    end
  end
end
