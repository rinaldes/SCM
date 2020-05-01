class CreatePurchaseRequests < ActiveRecord::Migration
  def change
    create_table :purchase_requests do |t|
    	t.string	:number
    	t.date		:date
    	t.integer	:supplier_id
    	t.string	:status
    	t.integer	:grand_total
      t.timestamps
    end
  end
end
