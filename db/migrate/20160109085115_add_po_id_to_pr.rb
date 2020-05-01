class AddPoIdToPr < ActiveRecord::Migration
  def change
    add_column :purchase_requests, :purchase_order_id, :integer
  end
end
