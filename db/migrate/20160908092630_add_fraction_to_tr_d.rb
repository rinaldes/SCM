class AddFractionToTrD < ActiveRecord::Migration
  def change
    add_column :purchase_request_details, :fraction, :integer
    add_column :receiving_details, :fraction, :integer
    add_column :purchase_order_details, :fraction, :integer
  end
end
