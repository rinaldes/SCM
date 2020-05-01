class AddColumnPurchasing < ActiveRecord::Migration
  def change
  	add_column	:purchase_requests, :note, :text
  	add_column	:purchase_orders, :note, :text
  	add_column	:receivings, :note, :text
  	add_column 	:purchase_orders, :purchase_request_id, :integer
  	add_column	:receivings, :purchase_order_id, :integer
  end
end
