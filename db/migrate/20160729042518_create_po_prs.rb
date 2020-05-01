class CreatePoPrs < ActiveRecord::Migration
  def change
    create_table :po_prs do |t|
      t.integer :purchase_request_id
      t.integer :purchase_order_id
      t.timestamps
    end
  end
end
